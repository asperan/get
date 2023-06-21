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

require 'singleton'

# Base class for (sub)commands.
class Command
  include Singleton

  attr_reader :usage, :description, :action, :subcommands, :option_parser

  protected

  attr_writer :usage, :description, :action, :subcommands, :option_parser

  def initialize
    super
    yield self if block_given?
    setup_option_parser
    if @option_parser.nil?
      raise("No variable '@option_parser' has been created in the option_parser setup of command #{self.class.name}.")
    end

    setup_action
    return unless @action.nil?

    raise("No variable '@action' has been created in the action setup of the command #{self.class.name}")
  end

  @description = ''
  @subcommands = {}

  # This method must be overridden by subclasses to create a new option parser in a '@option_parser' variable.
  # Do not call 'super' in the new implementation.
  def setup_option_parser
    raise("Error: command #{self.class.name} do not have a defined option parser.")
  end

  # This method must be overridden by subclasses to create a new option parser in a '@action' variable.
  # Do not call 'super' in the new implementation.
  def setup_action
    raise("Error: command #{self.class.name} do not have a defined action.")
  end

  def full_description
    description + if subcommands.empty?
                    ''
                  else
                    subcommand_max_length = subcommands.keys.map { |k| k.to_s.length }.max || 0
                    <<~SUBCOMMANDS.chomp
                      \n
                      Subcommands:
                      #{subcommands.keys.map { |k| "  #{k.to_s.ljust(subcommand_max_length)} => #{subcommands[k].description}" }.join("\n")}
                    SUBCOMMANDS
                  end
  end

  def stop_condition
    subcommands.keys.map(&:to_s)
  end

  def educated_error(message)
    Common.error message do
      @option_parser.educate
    end
  end
end
