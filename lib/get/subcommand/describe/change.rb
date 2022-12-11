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

# Module which handles change-related tasks.
module ChangeHandler
  # Array with change types in ascending order of importance.
  CHANGE_TYPE = %i[NONE PATCH MINOR MAJOR].freeze

  @@major_trigger = 'is_breaking'
  @@minor_trigger = "type == 'feat'"
  @@patch_trigger = "type == 'fix'"

  module_function

  # In this block method arguments can be used by user.
  # Also `eval` is needed to allow users to define their custom triggers.
  # rubocop:disable Lint/UnusedMethodArgument
  # rubocop:disable Security/Eval
  def triggers_major?(type, scope, is_breaking)
    eval(@@major_trigger)
  end

  def triggers_minor?(type, scope)
    eval(@@minor_trigger)
  end

  def triggers_patch?(type, scope)
    eval(@@patch_trigger)
  end
  # rubocop:enable Lint/UnusedMethodArgument
  # rubocop:enable Security/Eval

  # Open String class to inject method to convert a (commit) string into
  # a change.
  class ::String
    # Convert the string (as a conventional commit string) into a change type.
    def to_change
      groups = Common::CONVENTIONAL_COMMIT_REGEX.match(self)
      return :MAJOR if ChangeHandler.triggers_major?(groups[1], groups[3], !groups[4].nil?)
      return :MINOR if ChangeHandler.triggers_minor?(groups[1], groups[2])
      return :PATCH if ChangeHandler.triggers_patch?(groups[1], groups[2])

      :NONE
    end
  end

  public

  def greatest_change_in(commit_list)
    commit_list
      .grep(Common::CONVENTIONAL_COMMIT_REGEX)
      .map(&:to_change)
      .max { |a, b| CHANGE_TYPE.index(a) <=> CHANGE_TYPE.index(b) }
  end
end
