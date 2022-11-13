# frozen_string_literal: true

require 'optimist'

require 'get/subcommand/describe'
require 'get/version'
require 'get/common'

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
    command = ARGV.shift.to_sym
    if @@subcommands.include?(command)
      @@subcommands[command].action.call
    else
      error "Unknown subcommand '#{command}'"
    end
  end

  def self.is_module?
    true
  end

  def self.error(message)
    Common.error message do
      @@option_parser.educate
    end
  end
end
