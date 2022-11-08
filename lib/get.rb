# frozen_string_literal: true

require 'optimist'

require_relative './get/subcommand/describe'
require_relative './get/version'

# Entrypoint of Get
module Get
  class Error < StandardError; end

  @@subcommands = { describe: Describe.command, }
  @@option_parser = Optimist::Parser.new do
    subcommand_max_length = @@subcommands.keys.map { |k| k.to_s.length }.max
    usage '-h|-v|(<subcommand> [<subcommand-options])'
    synopsis <<~SUBCOMMANDS unless @@subcommands.empty?
      Subcommands:
      #{@@subcommands.keys.map { |k| "  #{k.to_s.ljust(subcommand_max_length)} => #{@@subcommands[k].description}" }.join("\n")}
    SUBCOMMANDS
    version "Get version: #{Get::VERSION}"
    educate_on_error
    stop_on @@subcommands.keys.map(&:to_s)
  end

  def self.main
    options = Optimist.with_standard_exception_handling(@@option_parser) do
      @@option_parser.parse
    end
    error 'No command or option specified' if ARGV.empty?
    command = ARGV.shift
    if @@subcommands.include?(command.to_sym)
      @@subcommands[command.to_sym].action.call
    else
      error "Unknown subcommand '#{command}'"
    end
  end

  def self.is_module?
    true
  end

  def self.error(message)
    # Change the stdout to stderr for Optimist.educate, as it uses stdout by default
    # and this method is used in case of errors.
    $stdout = $stderr
    puts message.to_s
    Optimist.educate
    exit(1)
  end
end
