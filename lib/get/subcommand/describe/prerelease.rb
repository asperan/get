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

# Module with methods for managing prerelease updates.
module PrereleaseHandler
  FIRST_PRERELEASE = 1
  DEFAULT_PRERELEASE_STRING = 'dev'
  PRERELEASE_PLACEHOLDER = '(p)'
  DEFAULT_PRERELEASE_PATTERN = "#{DEFAULT_PRERELEASE_STRING}#{PRERELEASE_PLACEHOLDER}".freeze

  Common.module_instance_attr(self, 'prerelease_pattern', :DEFAULT_PRERELEASE_PATTERN)
  Common.module_instance_attr(self, 'old_prerelease_pattern', 'proc { prerelease_pattern }')

  def compute_prerelease(current_prerelease, need_reset: false)
    pattern_changed = PrereleaseHandler.prerelease_pattern != actual_old_prerelease_pattern
    new_prerelease = (need_reset || pattern_changed ? FIRST_PRERELEASE : (extract_prerelease_number(current_prerelease) + 1)).to_s
    PrereleaseHandler.prerelease_pattern.sub(PRERELEASE_PLACEHOLDER, new_prerelease)
  end

  private

  def extract_prerelease_number(current_prerelease)
    Common.error "The given old pattern does not contains the placeholder '(p)'" unless
      actual_old_prerelease_pattern.include?(PRERELEASE_PLACEHOLDER)
    old_prerelease_regex = actual_old_prerelease_pattern.sub(PRERELEASE_PLACEHOLDER, '(\\d+)')
    begin
      Regexp.new(old_prerelease_regex).match(current_prerelease)[1].to_i
    rescue NoMethodError
      Common.error "The given old prerelease pattern '#{actual_old_prerelease_pattern}' " \
                   "does not match the analyzed prerelease: '#{current_prerelease}'."
    end
  end

  def actual_old_prerelease_pattern
    if PrereleaseHandler.old_prerelease_pattern.respond_to?('call')
      PrereleaseHandler.old_prerelease_pattern.call
    else
      PrereleaseHandler.old_prerelease_pattern
    end
  end
end
