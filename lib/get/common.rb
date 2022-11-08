# frozen_string_literal: true

# Utility module
module Common
  # Check if the command is called while in a git repository.
  # If the command fails, it is assumed to not be in a git repository.
  def self.in_git_repo?
    system('git rev-parse --is-inside-work-tree &>/dev/null')
  end

  # Print an error message and optionally run a block.
  # Stdout becomes stderr, so every print is performed to stderr.
  # This behavior is wanted as this method is called on errors.
  def self.error(message)
    $stdout = $stderr
    puts "Error: #{message}"
    yield if block_given?
    exit(1)
  end
end