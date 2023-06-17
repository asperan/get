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

require 'optimist'

require 'get/subcommand/describe/describe'
require 'get/subcommand/commit/commit'
require 'get/subcommand/init/init'
require 'get/subcommand/license/license'
require 'get/subcommand/complete/complete'
require 'get/subcommand/changelog/changelog'
require 'get/subcommand/tree/tree'
require 'get/version'
require 'get/commons/common'
require 'get/subcommand/command'

# Main command of Get.
class Get < Command
  class Error < StandardError; end

  def initialize
    super() do
      @usage = '-h|-v|(<subcommand> [<subcommand-options])'
      @description = ''
      @subcommands = {
        describe: Describe.instance,
        commit: Commit.command,
        init: Init.instance,
        license: License.command,
        complete: Complete.command,
        changelog: Changelog.command,
        tree: Tree.command,
      }
    end
    @option_parser = Optimist::Parser.new(
      @usage,
      full_description,
      GET_VERSION,
      stop_condition
    ) do |usage_header, description, version, stop_condition|
      usage usage_header
      synopsis description
      version "Get version: #{version}"
      educate_on_error
      stop_on stop_condition
    end
  end

  def main
    @options = Optimist.with_standard_exception_handling(@option_parser) do
      @option_parser.parse
    end
    error 'No command or option specified' if ARGV.empty?
    command = ARGV.shift.to_sym
    if @subcommands.include?(command)
      @subcommands[command].action.call
    else
      error "Unknown subcommand '#{command}'"
    end
  end

  def self.error(message)
    Common.error message do
      @option_parser.educate
    end
  end
end
