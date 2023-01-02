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
require 'get/common'
require 'get/subcommand/command'
require 'get/subcommand/commit/prompt'

# Class length is disabled as most of its length is given by formatting.
# rubocop:disable Metrics/ClassLength
# Subcommand, it manages the description of the current git repository using semantic version.
class Commit < Command
  def self.command
    @@command ||= new
    @@command
  end

  private_class_method :new

  private

  include PromptHandler

  @@command = nil

  @@usage = 'commit -h|(<subcommand> [<subcommand-options])'
  @@description = 'Create a new semantic commit'
  @@subcommands = {}
  # This block is Optimist configuration. It is as long as the number of options of the command.
  # rubocop:disable Metrics/BlockLength
  @@commit_parser = Optimist::Parser.new do
    subcommand_max_length = @@subcommands.keys.map { |k| k.to_s.length }.max
    usage @@usage
    synopsis <<~SUBCOMMANDS unless @@subcommands.empty?
      Subcommands:
      #{@@subcommands.keys.map { |k| "  #{k.to_s.ljust(subcommand_max_length)} => #{@@subcommands[k].description}" }.join("\n")}
    SUBCOMMANDS
    opt :type,
        'Define the type of the commit. Enabling this option skips the type selection.',
        { type: :string }
    opt :scope,
        'Define the scope of the commit. Enabling this option skips the scope selection.',
        { type: :string, short: 'S' }
    opt :summary,
        'Define the summary message of the commit. Enabling this option skips the summary message prompt.',
        { type: :string, short: 's' }
    opt :message,
        'Define the message body of the commit. Enabling this option skips the message body prompt.',
        { type: :string }
    opt :breaking,
        'Set the commit to have a breaking change. ' \
        'Can be negated with "--no-breaking". ' \
        'Enabling this option skips the breaking change prompt.',
        { type: :flag, short: :none }
    educate_on_error
    stop_on @@subcommands.keys.map(&:to_s)
  end
  # rubocop:enable Metrics/BlockLength

  def initialize
    super(@@usage, @@description) do
      Common.error 'commit need to be run inside a git repository' unless Common.in_git_repo?
      @options = Common.with_subcommand_exception_handling @@commit_parser do
        @@commit_parser.parse
      end

      message = full_commit_message
      puts message
      output = `git commit --no-status -m '#{message}'`
      Common.error "git commit failed: #{output}" if $CHILD_STATUS.exitstatus.positive?
    end
  end

  def full_commit_message
    type = commit_type
    scope = commit_scope
    breaking = commit_breaking?
    summary = commit_summary
    body = commit_body
    "#{type}" \
      "#{scope.nil? || scope.empty? ? '' : "(#{scope})"}" \
      "#{breaking ? '!' : ''}" \
      ": #{summary}" \
      "#{body.empty? ? '' : "\n\n#{body}"}"
  end

  def commit_type
    if @options[:type_given]
      @options[:type]
    else
      ask_for_type
    end.to_s.strip
  end

  def commit_scope
    if @options[:scope_given]
      @options[:scope]
    else
      ask_for_scope
    end.to_s.strip
  end

  def commit_breaking?
    if @options[:breaking_given]
      @options[:breaking]
    else
      ask_for_breaking
    end
  end

  def commit_summary
    if @options[:summary_given]
      @options[:summary]
    else
      ask_for_summary
    end.to_s.strip
  end

  def commit_body
    if @options[:message_given]
      @options[:message]
    else
      ask_for_message
    end.to_s.strip
  end
end
# rubocop:enable Metrics/ClassLength
