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
require 'get/commons/git'
require 'get/subcommand/command'

# Class length is disabled as most of its length is given by formatting.
# rubocop:disable Metrics/ClassLength
# Subcommand, it allow to create a new repository and add an initial, empty commit to it.
class Tree < Command
  def self.command
    @@command ||= new
    @@command
  end

  private_class_method :new

  private

  @@command = nil

  @@usage = 'tree -h|(<subcommand> [<subcommand-options])'
  @@description = 'Print the tree of commits.'
  @@subcommands = {}
  # This block is Optimist configuration. It is as long as the number of options of the command.
  # rubocop:disable Metrics/BlockLength
  @@option_parser = Optimist::Parser.new do
    subcommand_max_length = @@subcommands.keys.map { |k| k.to_s.length }.max
    subcommand_section = <<~SUBCOMMANDS unless @@subcommands.empty?
      Subcommands:
      #{@@subcommands.keys.map { |k| "  #{k.to_s.ljust(subcommand_max_length)} => #{@@subcommands[k].description}" }.join("\n")}
    SUBCOMMANDS
    usage @@usage
    synopsis @@description + (subcommand_section.nil? ? '' : "\n") + subcommand_section.to_s
    educate_on_error
    stop_on @@subcommands.keys.map(&:to_s)
  end
  # rubocop:enable Metrics/BlockLength

  def initialize
    super(@@usage, @@description) do
      @options = Common.with_subcommand_exception_handling @@option_parser do
        @@option_parser.parse
      end
      Common.error 'tree need to be run inside a git repository' unless Git.in_repo?

      view_tree
    end
  end

  def view_tree
    page_log(transform_log(log))
  end

  TREE_FORMAT = '%C(bold blue)%h%C(reset)§%C(dim normal)(%cr)%C(reset)§%C(auto)%d%C(reset)§§%n' \
                '§§§       %C(normal)%an%C(reset)%C(dim normal): %s%C(reset)'

  def log
    `git log --all --graph --decorate=short --date-order --color --pretty=format:"#{TREE_FORMAT}"`
  end

  TIME_REGEX = /(\([a-z0-9 ,]+\))/
  TIME_MINIMUM_PADDING = 2

  def transform_log(text)
    return 'This repository has no commit.' if text.empty?

    split_lines = text.split("\n").map { |element| element.split('§') }
    # The first line is always a commit line, so it always have a time reference
    first_line_time = split_lines.first[1]
    # calc color escape codes length
    time_color_length = first_line_time.length - first_line_time.match(TIME_REGEX)[1].length

    # calc max length of time references
    time_padding = 0
    split_lines.each { |element| time_padding = [time_padding, element[1].length - time_color_length].max }

    # format strings
    split_lines
      .map do |element|
        # Only lines with the date reference have the color escape codes,
        # the other lines do not need the additional padding
        left_padding = TIME_MINIMUM_PADDING + time_padding +
                       (element[1].match?(TIME_REGEX) ? time_color_length : 0)
        format(
          '%<date>s %<tree_mark>s %<pointers>s %<commit_text>s',
          {
            date: element[1].rjust(left_padding),
            tree_mark: element[0],
            pointers: element[2],
            commit_text: element[3]
          }
        )
      end
      .join("\n")
  end

  def page_log(text)
    system("less -RfS <(echo -e '#{text}')")
  end
end
# rubocop:enable Metrics/ClassLength
