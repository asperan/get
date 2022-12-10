# Get is a toolbox based on git which simplifies the adoption of conventions and some git commands.
# Copyright (C) 2022  Alex Speranza

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
require 'get/subcommand/describe/change'
require 'get/subcommand/describe/prerelease'
require 'get/subcommand/describe/metadata'

# Class length is disabled as most of its length is given by formatting.
# rubocop:disable Metrics/ClassLength
# Subcommand, it manages the description of the current git repository using semantic version.
class Describe < Command
  def self.command
    @@command ||= new
    @@command
  end

  private_class_method :new

  private

  include ChangeHandler
  include PrereleaseHandler
  include MetadataHandler

  @@command = nil

  DEFAULT_RELEASE_VERSION = '0.1.0'
  FULL_SEMANTIC_VERSION_REGEX = /
      ^((0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)) # Stable version, major, minor, patch
      (?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))? # prerelease
      (?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$ # metadata
    /x

  @@usage = 'describe -h|(<subcommand> [<subcommand-options])'
  @@description = 'Describe the current git repository with semantic version'
  @@subcommands = {}
  # This block is Optimist configuration. It is as long as the numebr of options of the command.
  # rubocop:disable Metrics/BlockLength
  @@describe_parser = Optimist::Parser.new do
    subcommand_max_length = @@subcommands.keys.map { |k| k.to_s.length }.max
    usage @@usage
    synopsis <<~SUBCOMMANDS unless @@subcommands.empty?
      Subcommands:
      #{@@subcommands.keys.map { |k| "  #{k.to_s.ljust(subcommand_max_length)} => #{@@subcommands[k].description}" }.join("\n")}
    SUBCOMMANDS
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
    stop_on @@subcommands.keys.map(&:to_s)
  end
  # rubocop:enable Metrics/BlockLength

  def initialize
    super(@@usage, @@description) do
      Common.error 'describe need to be run inside a git repository' unless Common.in_git_repo?
      @options = with_describe_exception_handling @@describe_parser do
        @@describe_parser.parse
      end
      @@major_trigger = @options[:major_trigger] if @options[:major_trigger_given]
      @@minor_trigger = @options[:minor_trigger] if @options[:minor_trigger_given]
      @@patch_trigger = @options[:patch_trigger] if @options[:patch_trigger_given]
      @@old_prerelease_pattern = @options[:old_prerelease_pattern] if @options[:old_prerelease_pattern_given]
      @@prerelease_pattern = @options[:prerelease_pattern] if @options[:prerelease_pattern_given]
      current_commit_version = describe_current_commit
      puts current_commit_version
      create_signed_tag(current_commit_version) if @options[:create_tag]
    end
  end

  def with_describe_exception_handling(parser)
    yield
  rescue Optimist::CommandlineError => e
    parser.die(e.message, nil, e.error_code)
  rescue Optimist::HelpNeeded
    parser.educate
    exit
  rescue Optimist::VersionNeeded
    # Version is not needed in this command
  end

  def describe_current_commit
    last_version = last_tag_matching(FULL_SEMANTIC_VERSION_REGEX)
    return last_version if with_commit_list_from(last_version, &:empty?)

    puts "Last version: #{last_version}" if @options[:diff]
    last_release = last_tag_matching(FULL_SEMANTIC_VERSION_REGEX) { |match_data| match_data[5].nil? }
    if @options[:prerelease]
      prepare_prerelease_tag(last_release, last_version)
    else
      prepare_release_tag(last_release)
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

  # Return the last tag matching a regex, or nil if none matches.
  def last_tag_matching(regex, &additional_conditions_on_match)
    tag_list = `git --no-pager tag --list --sort=-v:refname --merged`.split("\n")
    filtered_tag_list = tag_list.filter do |element|
      regex.match?(element) && (!block_given? || additional_conditions_on_match.call(regex.match(element)))
    end
    if filtered_tag_list.empty?
      nil
    else
      filtered_tag_list.first
    end
  end

  def updated_stable_version(stable_version)
    return DEFAULT_RELEASE_VERSION if stable_version.nil?

    greatest_change_from_stable_version = with_commit_list_from(stable_version) do |commits_from_version|
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

  # Run a block of code with the list of commits from the given version as an argument.
  # If the block is not given, this method is a nop.
  def with_commit_list_from(version = nil, &block)
    return unless block_given?

    commits_from_version =
      `git --no-pager log --oneline --pretty=format:%s #{version.nil? ? '' : "^#{version}"} HEAD`
      .split("\n")
    block.call(commits_from_version)
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
