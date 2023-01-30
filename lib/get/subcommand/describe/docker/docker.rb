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

require 'get/subcommand/command'

# Class length is disabled as most of its length is given by formatting.
# rubocop:disable Metrics/ClassLength
# Subcommand, it manages the description of the current git repository using semantic version.
class DescribeDocker < Command
  def self.command
    @@command ||= new
    @@command
  end

  private_class_method :new

  private

  INCREMENTAL_VERSION_PATTERN = /(((\d+)\.\d+)\.\d+)/

  @@command = nil

  @@usage = 'describe docker -h|(<subcommand> [<subcommand-options])'
  @@description = 'Describe the current git repository with a list of version for docker'
  @@subcommands = {}
  # This block is Optimist configuration. It is as long as the number of options of the command.
  # rubocop:disable Metrics/BlockLength
  @@describe_parser = Optimist::Parser.new do
    subcommand_max_length = @@subcommands.keys.map { |k| k.to_s.length }.max
    usage @@usage
    synopsis <<~SUBCOMMANDS unless @@subcommands.empty?
      Subcommands:
      #{@@subcommands.keys.map { |k| "  #{k.to_s.ljust(subcommand_max_length)} => #{@@subcommands[k].description}" }.join("\n")}
    SUBCOMMANDS
    opt :separator,
        'Use the given value as separator for versions',
        { type: :string, default: '\n' }
    opt :not_latest,
        'Do not include "latest" in the version list.',
        short: :none
    opt :substitute_plus,
        'Set which character will be used in place of "+".',
        { type: :string, short: :none }
    educate_on_error
    stop_on @@subcommands.keys.map(&:to_s)
  end
  # rubocop:enable Metrics/BlockLength

  def initialize
    super(@@usage, @@description) do |version|
      Common.error 'describe need to be run inside a git repository' unless Common.in_git_repo?
      @options = Common.with_subcommand_exception_handling @@describe_parser do
        @@describe_parser.parse
      end
      set_options

      puts version_list_from(version).join(@@separator)
    end
  end

  def set_options
    @@separator = if @options[:separator_given]
                    @options[:separator]
                  else
                    "\n"
                  end
    @@not_latest = @options[:not_latest]
    @@plus_substitution = if @options[:substitute_plus_given]
                            @options[:substitute_plus]
                          else
                            '+'
                          end
  end

  def version_list_from(full_version)
    [
      full_version.sub('+', @@plus_substitution),
      reduced_versions(full_version),
      latest
    ]
  end

  def reduced_versions(full_version)
    base_version = full_version.partition('+')[0]
    if base_version.include?('-')
      base_version
    else
      INCREMENTAL_VERSION_PATTERN.match(base_version).captures
    end
  end

  def latest
    if @options[:not_latest]
      []
    else
      ['latest']
    end
  end
end
# rubocop:enable Metrics/ClassLength
