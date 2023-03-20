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
require 'get/subcommand/command'
require 'get/subcommand/complete/bash_completion'
require 'get'

# Class length is disabled as most of its length is given by formatting.
# rubocop:disable Metrics/ClassLength
# Subcommand, prints the bash completion script.
class Complete < Command
  def self.command
    @@command ||= new
    @@command
  end

  private_class_method :new

  private

  include BashCompletion

  @@command = nil

  @@usage = 'complete -h|(<subcommand> [<subcommand-options])'
  @@description = 'Print the shell completion script'
  @@subcommands = {}
  # This block is Optimist configuration. It is as long as the number of options of the command.
  # rubocop:disable Metrics/BlockLength
  @@option_parser = Optimist::Parser.new do
    subcommand_max_length = @@subcommands.keys.map { |k| k.to_s.length }.max
    usage @@usage
    synopsis <<~SUBCOMMANDS unless @@subcommands.empty?
      Subcommands:
      #{@@subcommands.keys.map { |k| "  #{k.to_s.ljust(subcommand_max_length)} => #{@@subcommands[k].description}" }.join("\n")}
    SUBCOMMANDS
    opt :shell,
        'Select the type of shell of which the completion will be generated.',
        { type: :string, default: 'bash' }
    educate_on_error
    stop_on @@subcommands.keys.map(&:to_s)
  end
  # rubocop:enable Metrics/BlockLength

  def initialize
    super(@@usage, @@description) do
      @options = Common.with_subcommand_exception_handling @@option_parser do
        @@option_parser.parse
      end

      @completions = {
        bash: proc { bash_completion(Get, 'get') }
      }

      selected_shell = @options[:shell].to_sym

      Common.error "Completion for shell '#{selected_shell}' not available." unless @completions.key?(selected_shell)

      puts @completions[selected_shell].call
    end
  end
end
# rubocop:enable Metrics/ClassLength
