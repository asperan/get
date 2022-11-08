# frozen_string_literal: true

require_relative 'command'

# Subcommand, it manages the description of the current git repository using semantic version.
class Describe < Command
  def self.command
    @@command ||= new
    @@command
  end

  private_class_method :new

  private

  @@command = nil

  @@usage = 'describe -h|(<subcommand> [<subcommand-options])'
  @@description = 'Describe the current git repository with semantic version'
  @@subcommands = {}
  @@describe_parser = Optimist::Parser.new do
    subcommand_max_length = @@subcommands.keys.map { |k| k.to_s.length }.max
    # banner @@description
    usage @@usage
    synopsis <<~SUBCOMMANDS unless @@subcommands.empty?
      Subcommands:
      #{@@subcommands.keys.map { |k| "  #{k.to_s.ljust(subcommand_max_length)} => #{@@subcommands[k].description}" }.join("\n")}
    SUBCOMMANDS
    educate_on_error
    stop_on @@subcommands.keys.map(&:to_s)
  end

  def initialize
    super(@@usage, @@description) do
      Common.error 'describe need to be run inside a git repository' unless Common.in_git_repo?
      @options = with_describe_exception_handling @@describe_parser do
        @@describe_parser.parse
      end
      puts "I'm describe command"
      # `git describe || echo "0.1.0"`
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
end
