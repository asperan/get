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

require 'get/common'
require 'get/subcommand/command'
require 'get/subcommand/license/license_retriever'

# Class length is disabled as most of its length is given by formatting.
# rubocop:disable Metrics/ClassLength
# Subcommand, it allow to choose a license.
class License < Command
  def self.command
    @@command ||= new
    @@command
  end

  private_class_method :new

  private

  include Retriever

  @@command = nil

  @@usage = 'license -h|(<subcommand> [<subcommand-options])'
  @@description = 'Create a new LICENSE file with the chosen license. ' \
                  'Online licenses are retrieved from https://choosealicense.com/appendix/ . ' \
                  'Head there for more information about the licences.'
  @@subcommands = {}
  # This block is Optimist configuration. It is as long as the number of options of the command.
  # rubocop:disable Metrics/BlockLength
  @@commit_parser = Optimist::Parser.new do
    subcommand_max_length = @@subcommands.keys.map { |k| k.to_s.length }.max
    subcommand_section = <<~SUBCOMMANDS unless @@subcommands.empty?
      Subcommands:
      #{@@subcommands.keys.map { |k| "  #{k.to_s.ljust(subcommand_max_length)} => #{@@subcommands[k].description}" }.join("\n")}
    SUBCOMMANDS
    usage @@usage
    synopsis @@description + (subcommand_section.nil? ? '' : "\n") + subcommand_section.to_s
    opt :offline,
        'Force the application to use the offline licenses.'
    opt :create_commit,
        'Create a commit which adds the LICENSE file to the repository history.',
        short: :none
    opt :commit_type,
        'Select the type of the commit. No effect if "--create-commit" is not given.',
        default: 'chore'
    educate_on_error
    stop_on @@subcommands.keys.map(&:to_s)
  end
  # rubocop:enable Metrics/BlockLength

  def initialize
    super(@@usage, @@description) do
      @options = Common.with_subcommand_exception_handling @@commit_parser do
        @@commit_parser.parse
      end

      @filename = 'LICENSE'

      Common.error "The file '#{@filename}' already exists." if File.exist?(File.expand_path(@filename))

      create_license_file

      if @options[:create_commit]
        Common.error 'Not in a git repository: a commit cannot be created.' unless Common.in_git_repo?

        create_license_commit
      end
    end
  end

  def create_license_file
    license_text = ask_for_license(@options[:offline])
    File.write(File.expand_path(@filename), license_text)
    puts 'License file created. You may need to modify it with the year and your name.'
  end

  def create_license_commit
    `git stash push --staged`

    # This block is given to at_exit to execute it in any case.
    at_exit { `[ "$(git stash list | wc -l)" -gt "0" ] && git stash pop > /dev/null` }
    `git add "#{@filename}" && git commit -m "chore: add license file"`
    Common.error 'Failed to create license commit' if $CHILD_STATUS.exitstatus.positive?

    puts 'License file committed.'
  end
end
# rubocop:enable Metrics/ClassLength
