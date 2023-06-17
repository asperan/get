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

require 'get/commons/common'
require 'get/commons/git'
require 'get/subcommand/command'
require 'get/subcommand/describe/change'
require 'get/subcommand/describe/prerelease'
require 'get/subcommand/describe/metadata'
require 'get/subcommand/describe/docker/docker'

# Class length is disabled as most of its length is given by formatting.
# rubocop:disable Metrics/ClassLength
# Subcommand, it manages the description of the current git repository using semantic version.
# All its subcommands should have a method named "describe_current_commit" as it will be called.
class Describe < Command
  include Singleton

  private

  include ChangeHandler
  include PrereleaseHandler
  include MetadataHandler

  DEFAULT_RELEASE_VERSION = '0.1.0'
  FULL_SEMANTIC_VERSION_REGEX = /
      ^((0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)) # Stable version, major, minor, patch
      (?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))? # prerelease
      (?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$ # metadata
    /x

  def initialize
    super() do
      @usage = 'describe -h|(<subcommand> [<subcommand-options])'
      @description = 'Describe the current git repository with semantic version.'
      @subcommands = {
        docker: DescribeDocker.instance,
      }
    end
    # This block is Optimist configuration. It is as long as the number of options of the command.
    # rubocop:disable Metrics/BlockLength
    @option_parser = Optimist::Parser.new(
      @usage,
      full_description,
      stop_condition,
    ) do |usage_header, description, stop_condition|
      usage usage_header
      synopsis description
      opt :prerelease,
          'Describe a prerelease rather than a release',
          short: :none
      opt :exclude_metadata,
          'Do not include metadata in version.'
      opt :metadata,
          'Set which metadata to include in the string. ' \
          'Multiple value can be specified by separating the with a comma \',\'.',
          { type: :string, default: 'sha' }
      opt :major_trigger,
          'Set the trigger for a major release. ' \
          'This must be a valid Ruby expression. ' \
          'In this expression the string values "type" and "scope" ' \
          'and the boolean value "is_breaking" can be used.',
          { short: :none, type: :string, default: 'is_breaking' }
      opt :minor_trigger,
          'Set the trigger for a minor release. ' \
          'This must be a valid Ruby expression. ' \
          'In this expression the string values "type" and "scope" can be used.',
          { short: :none, type: :string, default: "type == 'feat'" }
      opt :patch_trigger,
          'Set the trigger for a patch release. ' \
          'This must be a valid Ruby expression. ' \
          'In this expression the string values "type" and "scope" can be used.',
          { short: :none, type: :string, default: "type == 'fix'" }
      opt :prerelease_pattern,
          'Set the pattern of the prerelease. This must contain the placeholder "(p)".',
          { short: :none, type: :string, default: 'dev(p)' }
      opt :old_prerelease_pattern,
          'Set the pattern of the old prerelease. It is useful for changing prerelease pattern.',
          { short: :none, type: :string, default: 'prerelease-pattern value' }
      opt :diff,
          'Print also the last version.'
      opt :create_tag,
          'Create a signed tag with the computed version.',
          { short: :none }
      opt :tag_message,
          'Add the given message to the tag. Requires "--create-tag".',
          { short: :none, type: :string }
      educate_on_error
      stop_on stop_condition
    end
    # rubocop:enable Metrics/BlockLength
    @action = lambda do
      @options = Common.with_subcommand_exception_handling @option_parser do
        @option_parser.parse
      end
      Common.error 'describe need to be run inside a git repository' unless Git.in_repo?
      set_options

      if ARGV.length.positive?
        subcommand = ARGV.shift.to_sym
        if @subcommands.include?(subcommand)
          @subcommands[subcommand].action.call(describe_current_commit)
        else
          # This error should not be disabled by -W0
          # rubocop:disable Style/StderrPuts
          $stderr.puts "Error: subcommand '#{subcommand}' unknown."
          # rubocop:enable Style/StderrPuts
          exit 1
        end
      else
        puts describe_current_commit
      end
    end
  end

  def set_options
    ChangeHandler.major_trigger = @options[:major_trigger] if @options[:major_trigger_given]
    ChangeHandler.minor_trigger = @options[:minor_trigger] if @options[:minor_trigger_given]
    ChangeHandler.patch_trigger = @options[:patch_trigger] if @options[:patch_trigger_given]
    PrereleaseHandler.old_prerelease_pattern = @options[:old_prerelease_pattern] if @options[:old_prerelease_pattern_given]
    PrereleaseHandler.prerelease_pattern = @options[:prerelease_pattern] if @options[:prerelease_pattern_given]
  end

  def describe_current_commit
    if Git.with_commit_list_from(Git.last_version, &:empty?)
      if Git.last_version.nil?
        Common.error('Cannot describe an empty repository.')
      else
        Git.last_version
      end
    else
      puts "Last version: #{Git.last_version}" if @options[:diff]

      current_commit_version = next_release
      create_signed_tag(current_commit_version) if @options[:create_tag]

      current_commit_version
    end
  end

  def next_release
    if @options[:prerelease]
      prepare_prerelease_tag(Git.last_release, Git.last_version)
    else
      prepare_release_tag(Git.last_release)
    end + metadata
  end

  def prepare_release_tag(last_release)
    updated_stable_version(last_release).to_s
  end

  def prepare_prerelease_tag(last_release, last_version)
    new_stable_version = updated_stable_version(last_release)
    base_version_match_data = FULL_SEMANTIC_VERSION_REGEX.match(last_version)
    no_changes_from_last_release = base_version_match_data[1] == new_stable_version && base_version_match_data[5].nil?
    Common.error 'No changes from last release' if no_changes_from_last_release
    new_stable_version +
      "-#{updated_prerelease(base_version_match_data[5], need_reset: base_version_match_data[1] != new_stable_version)}"
  end

  def updated_stable_version(stable_version)
    return DEFAULT_RELEASE_VERSION if stable_version.nil?

    greatest_change_from_stable_version = Git.with_commit_list_from(stable_version) do |commits_from_version|
      greatest_change_in(commits_from_version)
    end
    split_version = stable_version.split('.')
    case greatest_change_from_stable_version
    when :MAJOR
      "#{split_version[0].to_i + 1}.0.0"
    when :MINOR
      "#{split_version[0].to_i}.#{split_version[1].to_i + 1}.0"
    when :PATCH
      "#{split_version[0].to_i}.#{split_version[1].to_i}.#{split_version[2].to_i + 1}"
    else
      "#{split_version[0].to_i}.#{split_version[1].to_i}.#{split_version[2].to_i}"
    end
  end

  # Return the updated prerelease number
  def updated_prerelease(prerelease = nil, need_reset: false)
    compute_prerelease(prerelease, need_reset: prerelease.nil? || need_reset)
  end

  # Compute the metadata string
  def metadata
    return '' if @options[:exclude_metadata] || @options[:metadata].empty?

    "+#{compute_metadata(@options[:metadata])}"
  end

  def create_signed_tag(computed_version)
    system(
      'git tag -s ' \
      "#{
        if @options[:tag_message_given]
          "-m #{@options[:tag_message]}"
        else
          ''
        end
      } " \
      "'#{computed_version}'"
    )
  end
end
# rubocop:enable Metrics/ClassLength
