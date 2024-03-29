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
require_relative '../../commons/git'
require_relative '../command'

# Class length is disabled as most of its length is given by formatting.
# rubocop:disable Metrics/ClassLength
# Subcommand, it allow to create a new repository and add an initial, empty commit to it.
class Tree < Command
  private

  def initialize
    super() do
      @usage = 'tree -h|(<subcommand> [<subcommand-options])'
      @description = 'Print the tree of commits. ' \
                     'If the output is redirected to a pager (i.e. \'less\'), ' \
                     'you may need to enable the parsing of escape sequences.'
      @subcommands = {}
    end
  end

  def view_tree
    puts transform_log(log)
  end

  TREE_FORMAT = '%C(bold blue)%h%C(reset)§%C(dim normal)(%cr)%C(reset)§%C(auto)%d%C(reset)§§%n' \
                '§§§       %C(normal)%an%C(reset)%C(dim normal): %s%C(reset)'

  def log
    CommandIssuer.run(
      'git',
      'log',
      '--all',
      '--graph',
      '--decorate=short',
      '--date-order',
      '--color',
      "--pretty=format:\"#{TREE_FORMAT}\""
    ).output
  end

  TIME_REGEX = /(\([a-z0-9 ,]+\))/
  TIME_MINIMUM_PADDING = 2

  # rubocop:disable Metrics/MethodLength
  def transform_log(text)
    return 'This repository has no commit.' if text.empty?

    split_lines = text.split("\n").map { |element| element.split('§') }
    # The first line is always a commit line, so it always have a time reference
    first_line_time = split_lines.first[1]
    # calc color escape codes length
    time_color_length = first_line_time.length - first_line_time.match(TIME_REGEX)[1].length

    time_padding = global_fitting_time_padding(split_lines, time_color_length)

    split_lines
      .map do |element|
        # Only lines with the date reference have the color escape codes,
        # the other lines do not need the additional padding
        left_padding = TIME_MINIMUM_PADDING + time_padding +
          (!element[1].nil? && element[1].match?(TIME_REGEX) ? time_color_length : 0)
        format(
          '%<date>s %<tree_mark>s %<pointers>s %<commit_text>s',
          {
            date: (element[1].nil? ? '' : element[1]).rjust(left_padding),
            tree_mark: element[0],
            pointers: element[2],
            commit_text: element[3]
          }
        )
      end
      .join("\n")
  end
  # rubocop:enable Metrics/MethodLength

  def global_fitting_time_padding(lines, time_color_length)
    time_padding = 0
    lines
      # If element[1].nil? then the line refers to a intersection between branch lines
      # they do not have a time reference
      .reject { |element| element[1].nil? }
      .each { |element| time_padding = [time_padding, element[1].length - time_color_length].max }
    time_padding
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
      educate_on_error
      stop_on stop_condition
    end
  end

  def setup_action
    @action = lambda do
      @options = Common.with_subcommand_exception_handling @option_parser do
        @option_parser.parse
      end
      Common.error 'tree need to be run inside a git repository' unless Git.in_repo?

      view_tree
    end
  end
end
# rubocop:enable Metrics/ClassLength
