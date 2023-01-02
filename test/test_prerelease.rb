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

require 'test_helper'
require 'get/subcommand/describe/prerelease'

class TestChange < Minitest::Test

  include PrereleaseHandler

  def test_basic_extraction
    current_prerelease = 'dev2'
    assert_equal 2, extract_prerelease_number(current_prerelease)
  end

  def test_extract_with_different_prerelease_pattern
    original_prerelease_pattern = @@prerelease_pattern
    @@prerelease_pattern = '(p)'
    current_prerelease = '3'
    result = extract_prerelease_number(current_prerelease)
    @@prerelease_pattern = original_prerelease_pattern
    assert_equal 3, result
  end

  def test_change_prerelease_pattern_and_extract
    original_old_prerelase_pattern = @@old_prerelease_pattern
    @@old_prerelease_pattern = 'alpha(p)'
    current_prerelease = 'alpha3'
    result = extract_prerelease_number(current_prerelease)
    @@old_prerelease_pattern = original_old_prerelase_pattern
    assert_equal 3, result
  end

  def test_basic_prerelease_update
    current_prerelease = 'dev2'
    assert_equal 'dev3', compute_prerelease(current_prerelease)
  end
  
  def test_reset_prerelease
    current_prerelease = 'dev2'
    assert_equal 'dev1', compute_prerelease(current_prerelease, need_reset: true)
  end

  def test_update_with_prerelease_pattern_changed
    original_prerelease_pattern = @@prerelease_pattern
    original_old_prerelase_pattern = @@old_prerelease_pattern
    @@old_prerelease_pattern = 'alpha(p)'
    @@prerelease_pattern = 'beta(p)'
    current_prerelease = 'alpha3'
    result = compute_prerelease(current_prerelease)
    @@old_prerelease_pattern = original_old_prerelase_pattern
    @@prerelease_pattern = original_prerelease_pattern
    assert_equal 'beta4', result
  end
end
