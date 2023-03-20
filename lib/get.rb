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
require 'get/version'
require 'get/commons/common'

# Entrypoint of Get
module Get
  class Error < StandardError; end

  @@subcommands = {
    describe: Describe.command,
    commit: Commit.command,
    init: Init.command,
    license: License.command,
    complete: Complete.command,
  }
  @@option_parser = Optimist::Parser.new do
    subcommand_max_length = @@subcommands.keys.map { |k| k.to_s.length }.max
    usage '-h|-v|(<subcommand> [<subcommand-options])'
    synopsis <<~SUBCOMMANDS unless @@subcommands.empty?
      Subcommands:
      #{@@subcommands.keys.map { |k| "  #{k.to_s.ljust(subcommand_max_length)} => #{@@subcommands[k].description}" }.join("\n")}
    SUBCOMMANDS
    version "Get version: #{Get::VERSION}"
    educate_on_error
    stop_on @@subcommands.keys.map(&:to_s)
  end

  def self.main
    @options = Optimist.with_standard_exception_handling(@@option_parser) do
      @@option_parser.parse
    end
    error 'No command or option specified' if ARGV.empty?
    command = ARGV.shift.to_sym
    if @@subcommands.include?(command)
      @@subcommands[command].action.call
    else
      error "Unknown subcommand '#{command}'"
    end
  end

  def self.error(message)
    Common.error message do
      @@option_parser.educate
    end
  end
end
