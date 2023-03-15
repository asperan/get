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

require 'English'
require 'get/common'
require 'get/subcommand/command'

# Class length is disabled as most of its length is given by formatting.
# rubocop:disable Metrics/ClassLength
# Subcommand, it allow to create a new repository and add an initial, empty commit to it.
class Init < Command
  def self.command
    @@command ||= new
    @@command
  end

  private_class_method :new

  private

  @@command = nil

  @@usage = 'init -h|(<subcommand> [<subcommand-options])'
  @@description = 'Initialize a new git repository with an initial empty commit'
  @@subcommands = {}
  # This block is Optimist configuration. It is as long as the number of options of the command.
  # rubocop:disable Metrics/BlockLength
  @@option_parser = Optimist::Parser.new do
    subcommand_max_length = @@subcommands.keys.map { |k| k.to_s.length }.max
    usage @@usage
    synopsis <<~SUBCOMMANDS unless @@subcommands.empty?
      Subcommands:
      #{@@subcommands.keys.map { |k| "  #{k.to_s.ljust(subcommand_max_length)} => #{@@subcommands[k].description}" }.join("\n")}
    SUBCOMMANDS
    opt :empty,
        'Do not create the first, empty commit.'
    educate_on_error
    stop_on @@subcommands.keys.map(&:to_s)
  end
  # rubocop:enable Metrics/BlockLength

  def initialize
    super(@@usage, @@description) do
      @options = Common.with_subcommand_exception_handling @@option_parser do
        @@option_parser.parse
      end
      Common.error 'The current directory is already a git repository' if Common.in_git_repo?

      init_repository
    end
  end

  def init_repository
    `git init`
    Common.error 'Failed to init the repository' if $CHILD_STATUS.exitstatus.positive?

    create_first_commit unless @options[:empty]

    puts 'Git repository initialized'
  end

  def create_first_commit
    `git commit --allow-empty -m "chore: initialize repository"`
    Common.error 'Failed to create first commit' if $CHILD_STATUS.exitstatus.positive?
  end
end
# rubocop:enable Metrics/ClassLength
