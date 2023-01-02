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

require 'test_helper'
require 'get/subcommand/describe/change'

class TestChange < Minitest::Test

  COMMIT_LIST = [
    'refactor: move describe command file in the describe folder',
    'fix: remove options map print',
    'feat: implement the describe subcommand',
    'chore: add license header',
    'style: add space after magic comment',
    'feat: add module for handling changes',
    'style: add space after magic comment in version file',
    'feat: add module to manage prerelease updates',
    'feat: add module for metadata management',
    'style: disable AbcSize',
    'build: update required ruby version',
    'build: add ruby version file for rbenv',
    'chore: update dependencies',
    'refactor: update the version file headers',
    'refactor: reorder the headers of the version file',
    'feat: add license header in Rakefile',
    'fix: change bin script to use the ruby executable given by env',
    'feat: add executable to run the gem as a standalone command',
    'refactor: change require_relative into require',
    'fix: move methods inside the specification class',
    'build: add task to check syntax and task to run all other check tasks',
  ].freeze

  MODDED_COMMIT_LIST = [
    'refactor: move describe command file in the describe folder',
    'fix: remove options map print',
    'feat: implement the describe subcommand',
    'chore: add license header',
    'style: add space after magic comment',
    'feat: add module for handling changes',
    'style: add space after magic comment in version file',
    'feat: add module to manage prerelease updates',
    'feat: add module for metadata management',
    'style: disable AbcSize',
    'build: update required ruby version',
    'build: add ruby version file for rbenv',
    'chore!: update dependencies',
    'refactor: update the version file headers',
    'refactor: reorder the headers of the version file',
    'feat: add license header in Rakefile',
    'fix: change bin script to use the ruby executable given by env',
    'feat: add executable to run the gem as a standalone command',
    'refactor: change require_relative into require',
    'fix: move methods inside the specification class',
    'build: add task to check syntax and task to run all other check tasks',
  ].freeze

  include ChangeHandler

  def test_basic_change_detection
    assert_equal :MINOR, greatest_change_in(COMMIT_LIST)
  end

  def test_breaking_change_detection
    assert_equal :MAJOR, greatest_change_in(MODDED_COMMIT_LIST)
  end

  def test_modified_major_trigger
    original_major_trigger = @@major_trigger
    @@major_trigger = 'type == "chore"'
    result = greatest_change_in(COMMIT_LIST)
    @@major_trigger = original_major_trigger
    assert_equal :MAJOR, result
  end

  def test_modified_minor_trigger
    original_minor_trigger = @@minor_trigger
    @@minor_trigger = 'type == "docs"'
    result = greatest_change_in(COMMIT_LIST)
    @@minor_trigger = original_minor_trigger
    assert_equal :PATCH, result
  end

  def test_modified_patch_trigger
    original_patch_trigger = @@patch_trigger
    @@patch_trigger = 'type == "build"'
    result = greatest_change_in(COMMIT_LIST[9, 6])
    @@patch_trigger = original_patch_trigger
    assert_equal :PATCH, result
  end
end
