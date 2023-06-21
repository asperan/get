# Get is a toolbox based on git which simplifies the adoption of conventions and some git commands.
# Copyright (C) 2023  Alex Speranza

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program and the additional permissions granted by
# the Lesser GPL.  If not, see <https://www.gnu.org/licenses/>.

# frozen_string_literal: true

require 'highline'
require_relative '../../commons/git'

# Module for asking to the user information about a commit message.
module PromptHandler

  Common.module_instance_value(self, 'cli', 'HighLine.new')
  Common.module_instance_attr(self, 'custom_values_initialized', false)
  Common.module_instance_value(self, 'custom_types', [])
  Common.module_instance_value(self, 'custom_scopes', [])

  STRING_VALUE_VALIDATOR = /\s*\S+\s*/
  BODY_END_DELIMITER = "\n\n\n"

  DEFAULT_TYPES = %i[
    feat
    fix
    build
    chore
    ci
    docs
    style
    refactor
    perf
    test
  ].freeze

  def ask_for_type
    extract_types_and_scopes

    MOD_REF.cli.choose do |menu|
      menu.flow = :columns_down
      menu.prompt = 'Choose the type of your commit: '
      DEFAULT_TYPES.union(MOD_REF.custom_types).each do |type|
        menu.choice(type.to_sym)
      end
      menu.choice('Create a new type (rarely needed)') do |_|
        MOD_REF.cli.ask('Write the new type to use', String) do |question|
          question.verify_match = true
          question.validate = STRING_VALUE_VALIDATOR
        end
      end
    end
  end

  def ask_for_scope
    extract_types_and_scopes
    MOD_REF.cli.choose do |menu|
      menu.flow = :columns_down
      menu.prompt = 'Choose the scope of your commit: '
      MOD_REF.custom_scopes.each do |scope|
        menu.choice(scope.to_sym)
      end
      menu.choice('Create a new scope') do |_|
        MOD_REF.cli.ask('Write the new scope to use', String) do |question|
          question.verify_match = true
          question.validate = STRING_VALUE_VALIDATOR
        end
      end
      menu.choice('None') { '' }
    end
  end

  def ask_for_breaking
    MOD_REF.cli.agree('Does the commit contain a breaking change? (yes/no) ') do |question|
      question.default = false
    end
  end

  def ask_for_summary
    MOD_REF.cli.ask('The summary of the commit:') do |question|
      question.verify_match = true
      question.validate = STRING_VALUE_VALIDATOR
    end
  end

  def ask_for_message
    # This method needs a special implementation as the body message can span multiple lines.
    MOD_REF.cli.puts('The body of the commit (ends after 3 new lines):')
    MOD_REF.cli.input.gets(BODY_END_DELIMITER)
  end

  private

  FIRST_COMMIT = nil

  Common.add_module_self_reference(self)

  # This method tries to optimize input parsing by performing multiple operations in one go.
  # So its complexity is a bit higher as it needs to make multiple checks.
  # rubocop:disable Metrics/CyclomaticComplexity
  def extract_types_and_scopes
    return if MOD_REF.custom_values_initialized

    Git.with_commit_list_from(FIRST_COMMIT) do |commit_list|
      commit_list.reverse.map do |element|
        match = Git::CONVENTIONAL_COMMIT_REGEX.match(element)
        next if match.nil?

        type_already_added = DEFAULT_TYPES.include?(match[1].to_sym) || MOD_REF.custom_types.include?(match[1])
        MOD_REF.custom_types.append(match[1]) unless type_already_added
        MOD_REF.custom_scopes.append(match[3]) unless match[3].nil? || MOD_REF.custom_scopes.include?(match[3])
      end
    end
    MOD_REF.custom_values_initialized = true
  end
  # rubocop:enable Metrics/CyclomaticComplexity
end
