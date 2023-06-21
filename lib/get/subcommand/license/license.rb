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

require 'get/commons/common'
require 'get/commons/git'
require 'get/subcommand/command'
require 'get/subcommand/license/license_retriever'

# Class length is disabled as most of its length is given by formatting.
# rubocop:disable Metrics/ClassLength
# Subcommand, it allow to choose a license.
class License < Command
  private

  include Retriever

  def initialize
    super() do
      @usage = 'license -h|(<subcommand> [<subcommand-options])'
      @description = 'Create a new LICENSE file with the chosen license. ' \
                     'Online licenses are retrieved from https://choosealicense.com/appendix/ . ' \
                     'Head there for more information about the licences.'
      @subcommands = {}
    end
  end

  def create_license_file
    license_text = ask_for_license(@options[:offline])
    File.write(File.expand_path(@filename), license_text)
    puts 'License file created. You may need to modify it with the year and your name.'
  end

  def create_license_commit
    CommandIssuer.run('git', 'stash', 'push', '--staged')

    setup_at_exit_hook
    CommandIssuer.run('git', 'add', "'#{@filename}'").then do |add_result|
      if add_result.exit_status.zero?
        CommandIssuer.run('git', 'commit', '-m', "'#{@options[:commit_type]}: add license file'").then do |commit_result|
          if commit_result.exit_status.positive?
            Common.error 'Failed to create license commit'
          else
            puts 'License file committed.'
          end
        end
      else
        Common.error "Failed to add license file '#{@filename}' to stage."
      end
    end
  end

  protected

  def setup_option_parser
    @option_parser = Optimist::Parser.new(
      @usage,
      full_description,
      stop_condition
    ) do |usage_header, description, stop_condition|
      usage usage_header
      synopsis description
      opt :offline,
          'Force the application to use the offline licenses.'
      opt :create_commit,
          'Create a commit which adds the LICENSE file to the repository history.',
          short: :none
      opt :commit_type,
          'Select the type of the commit. No effect if "--create-commit" is not given.',
          default: 'chore'
      educate_on_error
      stop_on stop_condition
    end
  end

  def setup_action
    @action = lambda do
      @options = Common.with_subcommand_exception_handling @option_parser do
        @option_parser.parse
      end

      @filename = 'LICENSE'

      Common.error "The file '#{@filename}' already exists." if File.exist?(File.expand_path(@filename))

      create_license_file

      if @options[:create_commit]
        Common.error 'Not in a git repository: a commit cannot be created.' unless Git.in_repo?

        create_license_commit
      end
    end
  end

  private

  def setup_at_exit_hook
    # This block is given to at_exit to execute it in any case.
    at_exit do
      if CommandIssuer.run('git', 'stash', 'list').output.lines.length.positive?
        CommandIssuer.run('git', 'stash', 'pop')
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
