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
require 'get/commons/common'
require 'get/commons/git'
require 'get/subcommand/command'

# Class length is disabled as most of its length is given by formatting.
# rubocop:disable Metrics/ClassLength
# Subcommand, it allow to create a new repository and add an initial, empty commit to it.
class Init < Command
  private

  def initialize
    super() do
      @usage = 'init -h|(<subcommand> [<subcommand-options])'
      @description = 'Initialize a new git repository with an initial empty commit.'
      @subcommands = {}
    end
    # This block is Optimist configuration. It is as long as the number of options of the command.
    # rubocop:disable Metrics/BlockLength
    @option_parser = Optimist::Parser.new(
      @usage,
      full_description,
      stop_condition
    ) do |usage_header, description, stop_condition|
      usage usage_header
      synopsis description
      opt :empty,
          'Do not create the first, empty commit.'
      educate_on_error
      stop_on stop_condition
    end
    # rubocop:enable Metrics/BlockLength
    @action = lambda do
      @options = Common.with_subcommand_exception_handling @option_parser do
        @option_parser.parse
      end
      Common.error 'The current directory is already a git repository' if Git.in_repo?

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
