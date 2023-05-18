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

# Utility module
module Git
  # Groups: 1 = type, 2 = scope with (), 3 = scope, 4 = breaking change, 5 = summary
  CONVENTIONAL_COMMIT_REGEX = /^(\w+)(\(([\w-]+)\))?(!)?:(.*)/

  # Check if the command is called while in a git repository.
  # If the command fails, it is assumed to not be in a git repository.
  def self.in_repo?
    system('git rev-parse --is-inside-work-tree &>/dev/null')
    case $CHILD_STATUS.exitstatus
    when 0 then true
    when 127 then Common.error '"git" is not installed.'
    else false
    end
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

  # Returns the last version and caches it for the next calls.
  def self.last_version
    @@last_version ||= `git describe --tags --abbrev=0`.strip
  end

  # Returns the last release and caches it for the next calls.
  def self.last_release
    @@last_release ||= `git --no-pager tag --list | sed 's/+/_/' | sort -V | sed 's/_/+/' | tail -n 1`.strip
  end
end
