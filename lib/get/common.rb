# Get is a toolbox based on git which simplifies the adoption of conventions and some git commands.
# Copyright (C) 2022  Alex Speranza

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
  # Check if the command is called while in a git repository.
  # If the command fails, it is assumed to not be in a git repository.
  def self.in_git_repo?
    system('git rev-parse --is-inside-work-tree &>/dev/null')
  end

  # Print an error message and optionally run a block.
  # Stdout becomes stderr, so every print is performed to stderr.
  # This behavior is wanted as this method is called on errors.
  def self.error(message)
    $stdout = $stderr
    puts "Error: #{message}"
    yield if block_given?
    exit(1)
  end
end
