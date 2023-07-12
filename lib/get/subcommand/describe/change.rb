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

# Module which handles change-related tasks.
module ChangeHandler
  # Array with change types in ascending order of importance.
  CHANGE_TYPE = %i[NONE PATCH MINOR MAJOR].freeze

  DEFAULT_MAJOR_TRIGGER = 'is_breaking'
  DEFAULT_MINOR_TRIGGER = "type == 'feat'"
  DEFAULT_PATCH_TRIGGER = "type == 'fix'"

  Common.module_instance_attr(self, 'major_trigger', :DEFAULT_MAJOR_TRIGGER)
  Common.module_instance_attr(self, 'minor_trigger', :DEFAULT_MINOR_TRIGGER)
  Common.module_instance_attr(self, 'patch_trigger', :DEFAULT_PATCH_TRIGGER)

  def updated_stable_version(stable_version)
    return Git::DEFAULT_RELEASE_VERSION if stable_version.nil?

    greatest_change_from_stable_version = Git.with_commit_list_from(stable_version) do |commits_from_version|
      greatest_change_in(commits_from_version)
    end
    split_version = stable_version.split('.')
    case greatest_change_from_stable_version
    when :MAJOR
      "#{split_version[0].to_i + 1}.0.0"
    when :MINOR
      "#{split_version[0].to_i}.#{split_version[1].to_i + 1}.0"
    when :PATCH
      "#{split_version[0].to_i}.#{split_version[1].to_i}.#{split_version[2].to_i + 1}"
    else
      "#{split_version[0].to_i}.#{split_version[1].to_i}.#{split_version[2].to_i}"
    end
  end

  private

  def greatest_change_in(commit_list)
    commit_list
      .grep(Git::CONVENTIONAL_COMMIT_REGEX)
      .map { |commit| to_change(commit) }
      .max { |a, b| CHANGE_TYPE.index(a) <=> CHANGE_TYPE.index(b) }
  end

  # In this block method arguments can be used by user.
  # Also `eval` is needed to allow users to define their custom triggers.
  # rubocop:disable Lint/UnusedMethodArgument
  # rubocop:disable Security/Eval
  def triggers_major?(type, scope, is_breaking)
    eval(ChangeHandler.major_trigger)
  end

  def triggers_minor?(type, scope)
    eval(ChangeHandler.minor_trigger)
  end

  def triggers_patch?(type, scope)
    eval(ChangeHandler.patch_trigger)
  end
  # rubocop:enable Lint/UnusedMethodArgument
  # rubocop:enable Security/Eval

  # Convert the string (as a conventional commit string) into a change type.
  def to_change(commit_message)
    groups = Git::CONVENTIONAL_COMMIT_REGEX.match(commit_message)
    return :MAJOR if triggers_major?(groups[1], groups[3], !groups[4].nil?)
    return :MINOR if triggers_minor?(groups[1], groups[3])
    return :PATCH if triggers_patch?(groups[1], groups[3])

    :NONE
  end
end
