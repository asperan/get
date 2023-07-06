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

require_relative './command_issuer'

# Utility module
module Git
  # Groups: 1 = type, 2 = scope with (), 3 = scope, 4 = breaking change, 5 = summary
  CONVENTIONAL_COMMIT_REGEX = %r{^(\w+)(\(([\w/-]+)\))?(!)?:(.*)}
  DEFAULT_RELEASE_VERSION = '0.1.0'
  # Groups:
  # 1 = full stable version ; 2,3,4 = major,minor,patch
  # 5 = prerelease ; 6 = metadata
  FULL_SEMANTIC_VERSION_REGEX = /
      ^((0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)) # Stable version, major, minor, patch
      (?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))? # prerelease
      (?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$ # metadata
    /x

  # Check if the command is called while in a git repository.
  # If the command fails, it is assumed to not be in a git repository.
  def self.in_repo?
    CommandIssuer.run('git', 'rev-parse', '--is-inside-work-tree').exit_status.zero?
  end

  # Run a block of code with the list of commits from the given version as an argument.
  # If the block is not given, this method is a nop.
  def self.with_commit_list_from(version = nil, &block)
    return unless block_given?

    command_result = CommandIssuer.run(
      'git',
      '--no-pager',
      'log',
      '--oneline',
      '--pretty=format:%s',
      version.nil? ? '' : "^#{version} HEAD"
    )
    commits_from_version = if command_result.exit_status.zero?
                             command_result.output.split("\n")
                           else
                             []
                           end
    block.call(commits_from_version)
  end

  # Returns the last version and caches it for the next calls.
  def self.last_version
    @last_version ||=
      CommandIssuer.run('git', 'describe', '--tags', '--abbrev=0')
                   .then { |result| result.output.strip if result.exit_status.zero? }
  end

  # Returns the last release and caches it for the next calls.
  def self.last_release
    @last_release ||=
      CommandIssuer.run('git', '--no-pager', 'tag', '--list', '--merged')
                   .then do |value|
        unless value.output.empty?
          value.output
               .split("\n")
               .select { |str| str.match(FULL_SEMANTIC_VERSION_REGEX)[5].nil? }
               .map { |str| str.sub('+', '_') }
               .sort
               .map { |str| str.sub('_', '+') }
               .last
        end
      end
  end
end
