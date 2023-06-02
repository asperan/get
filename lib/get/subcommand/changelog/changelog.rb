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
# Subcommand, generates a changelog.
class Changelog < Command
  def self.command
    @@command ||= new
    @@command
  end

  private_class_method :new

  private

  UNDEFINED_SCOPE = 'other'
  MARKDOWN_FORMAT = {
    title: '# %s',
    type: '## %s',
    scope: '### %s',
    list: '%s',
    item: '- %s'
  }.freeze

  @@command = nil

  @@usage = 'changelog -h|(<subcommand> [<subcommand-options])'
  @@description = 'Generate a changelog. Format options require a "%s" where the content must be.'
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
    opt :latest,
        'Generate the changelog from the latest version rather than the latest release'
    opt :title_format,
        'Set the symbol for the title.',
        { type: :string, short: 'T', default: '# %s' }
    opt :type_format,
        'Set the symbol for the commit types.',
        { type: :string, short: 't', default: '= %s' }
    opt :scope_format,
        'Set the symbol for the commit scopes.',
        { type: :string, short: 's', default: '- %s' }
    opt :list_format,
        'Set the symbol for lists.',
        { type: :string, short: 'l', default: '%s' }
    opt :item_format,
        'Set the symbol for list items.',
        { type: :string, short: 'i', default: '* %s' }
    opt :markdown,
        'Shortcut for `-T "# %s" -t "## %s" -s "### %s" -l "%s" -i "- %s"`. ' \
        'Can be overwritten by the single options.'
    educate_on_error
    stop_on @@subcommands.keys.map(&:to_s)
  end
  # rubocop:enable Metrics/BlockLength

  def initialize
    super(@@usage, @@description) do
      @options = Common.with_subcommand_exception_handling @@option_parser do
        @@option_parser.parse
      end
      Common.error 'changelog need to be run inside a git repository' unless Git.in_repo?
      @format = {}
      set_format

      puts changelog_from(@options[:latest] ? Git.last_version : Git.last_release)
    end
  end

  def set_format
    %w[title type scope list item].each do |element|
      @format[element.to_sym] = if @options[:markdown] && !@options["#{element}_given".to_sym]
                                  MARKDOWN_FORMAT[element.to_sym]
                                else
                                  unless @options["#{element}_format".to_sym].include? '%s'
                                    Common.error "The given format for '#{element}' must contain '%s'."
                                  end
                                  @options["#{element}_format".to_sym]
                                end
    end
  end

  def changelog_from(version)
    commit_map = {}

    Git.with_commit_list_from(version) do |list|
      list.each do |element|
        match_result = Git::CONVENTIONAL_COMMIT_REGEX.match(element)
        temp_hash = {
          match_result[1] => {
            (match_result[3] || UNDEFINED_SCOPE) => [match_result[5].strip.capitalize]
          }
        }
        commit_map.merge!(temp_hash) do |_key, old_value, new_value|
          old_value.merge(new_value) do |_inner_key, old_array, new_array|
            old_array + new_array
          end
        end
      end
    end

    format_changelog(version, commit_map)
  end

  def format_changelog(from_version, changelog)
    formatted_features = changelog.key?('feat') ? [format_type('feat', changelog['feat'])] : []
    formatted_fixes = changelog.key?('fix') ? [format_type('fix', changelog['fix'])] : []

    formatted_types = []
    changelog.except('feat', 'fix').each { |key, value| formatted_types.push(format_type(key, value)) }
    <<~CHANGELOG
      #{@format[:title].sub('%s', "Changelog from #{from_version.nil? ? 'first commit' : "version #{from_version}"}")}
      #{(formatted_features + formatted_fixes + formatted_types).join("\n").strip}
    CHANGELOG
  end

  def format_type(type, scopes)
    formatted_scopes = []
    scopes.each { |key, value| formatted_scopes.push(format_scope(key, value)) }
    <<~TYPE
      #{@format[:type].sub('%s', type.to_s)}
      #{formatted_scopes.join("\n").strip}
    TYPE
  end

  def format_scope(scope, commits)
    formatted_commits = []
    commits.each { |element| formatted_commits.push(@format[:item].sub('%s', element)) }
    <<~SCOPE
      #{@format[:scope].sub('%s', scope.to_s)}
      #{@format[:list].sub('%s', formatted_commits.join("\n"))}
    SCOPE
  end
end
# rubocop:enable Metrics/ClassLength
