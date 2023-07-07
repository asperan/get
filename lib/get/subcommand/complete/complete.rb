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

require_relative '../../commons/common'
require_relative '../command'
require_relative './bash_completion'
require_relative '../../../get'

# Class length is disabled as most of its length is given by formatting.
# rubocop:disable Metrics/ClassLength
# Subcommand, prints the bash completion script.
class Complete < Command
  private

  include BashCompletion

  def initialize
    super() do
      @usage = 'complete -h|(<subcommand> [<subcommand-options])'
      @description = 'Print the shell completion script. ' \
                     'Run \'get complete --info\' to learn how to install the completion.'
      @subcommands = {}
      @completions = {
        bash: {
          generator: proc { bash_completion(Get, 'get') },
          info: <<~INFO
            Add the following line to your .bashrc (or a sourced script):
            eval "$(get complete)" && complete -F _get_completion get
          INFO
        }
      }
    end
  end

  protected

  def setup_option_parser
    @option_parser = Optimist::Parser.new(
      @usage,
      full_description,
      stop_condition
    ) do |usage_header, description, stop_condition|
      usage usage_header
      synopsis description
      opt :shell,
          'Select the type of shell of which the completion will be generated.',
          { type: :string, default: 'bash' }
      opt :info,
          'Print the instructions to install the completion for the selected shell.',
          { short: :none }
      educate_on_error
      stop_on stop_condition
    end
  end

  def setup_action
    @action = lambda do
      @options = Common.with_subcommand_exception_handling @option_parser do
        @option_parser.parse
      end

      selected_shell = @options[:shell].to_sym

      print_info_and_exit(selected_shell) if @options[:info]

      Common.error "Completion for shell '#{selected_shell}' not available." unless @completions.key?(selected_shell)

      puts @completions[selected_shell][:generator].call
    end
  end

  def print_info_and_exit(selected_shell)
    puts @completions[selected_shell][:info]
    exit 0
  end
end
# rubocop:enable Metrics/ClassLength
