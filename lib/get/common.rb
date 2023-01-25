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

# Utility module
module Common
  # Groups: 1 = type, 2 = scope with (), 3 = scope, 4 = breaking change
  CONVENTIONAL_COMMIT_REGEX = /^(\w+)(\((\w+)\))?(!)?:.*/

  # Check if the command is called while in a git repository.
  # If the command fails, it is assumed to not be in a git repository.
  def self.in_git_repo?
    system('git rev-parse --is-inside-work-tree &>/dev/null')
  end

  # Print an error message and optionally run a block.
  # Stdout becomes stderr, so every print is performed to stderr.
  # This behavior is wanted as this method is called on errors.
  def self.error(message, &block)
    Common.print_then_do_and_exit("Error: #{message}", 1, block)
  end

  # Subcommand exception handling for Optimist.
  # Generally subcommands do not have a version to print.
  def self.with_subcommand_exception_handling(parser)
    yield
  rescue Optimist::CommandlineError => e
    parser.die(e.message, nil, e.error_code)
  rescue Optimist::HelpNeeded
    parser.educate
    exit
  rescue Optimist::VersionNeeded
    # Version is not needed in this command
  end

  # Run a block of code with the list of commits from the given version as an argument.
  # If the block is not given, this method is a nop.
  def self.with_commit_list_from(version = nil, &block)
    return unless block_given?

    commits_from_version =
      `git --no-pager log --oneline --pretty=format:%s #{version.nil? ? '' : "^#{version}"} HEAD`
      .split("\n")
    block.call(commits_from_version)
  end

  # Print the given message, execute a block if given,
  # and exit the program with the given exit status.
  # If exit_status is not 0, the stdout is redirected to stderr.
  def self.print_then_do_and_exit(message, exit_code = 0, action = proc {})
    $stdout = $stderr unless exit_code.zero?

    puts message
    action.call if action.respond_to?('call')
    exit(exit_code)
  end
end
