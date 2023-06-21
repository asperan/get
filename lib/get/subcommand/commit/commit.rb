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
require_relative './prompt'

# Class length is disabled as most of its length is given by formatting.
# rubocop:disable Metrics/ClassLength
# Subcommand, it manages the description of the current git repository using semantic version.
class Commit < Command
  private

  include PromptHandler

  def initialize
    super() do
      @usage = 'commit -h|(<subcommand> [<subcommand-options])'
      @description = 'Create a new semantic commit.'
      @subcommands = {}
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

  protected

  def setup_option_parser
    @option_parser = Optimist::Parser.new(@usage, full_description, stop_condition) do |usage_header, description, stop_condition|
      usage usage_header
      synopsis description
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
      opt :quiet,
          'Disable the print of the complete message.'
      educate_on_error
      stop_on stop_condition
    end
  end

  def setup_action
    @action = lambda do
      @options = Common.with_subcommand_exception_handling @option_parser do
        @option_parser.parse
      end
      Common.error 'commit need to be run inside a git repository' unless Git.in_repo?

      message = full_commit_message
      puts message unless @options[:quiet]
      command_result = CommandIssuer.run('git', 'commit', '--no-status', '-m', "\"#{message.gsub('"', '\"')}\"")
      Common.error "git commit failed: #{command_result.output}" if command_result.exit_status.positive?
    rescue Interrupt
      Common.print_then_do_and_exit "\nCommit cancelled"
    end
  end
end
# rubocop:enable Metrics/ClassLength
