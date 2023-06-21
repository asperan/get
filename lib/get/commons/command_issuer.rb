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

require 'open3'

# Module for simplify command execution.
module CommandIssuer
  # A class containing the result of a command, including the exit status and the command executed.
  class CommandResult
    attr_reader :command, :exit_status, :output, :error

    def initialize(command_string, exit_status, standard_output, standard_error)
      @command = command_string
      @exit_status = exit_status
      @output = standard_output
      @error = standard_error
    end
  end

  def self.run(executable, *args)
    full_path_executable = CommandIssuer.send(:find, executable)
    command = [full_path_executable, *args].join(' ').strip
    output, error, status = Open3.capture3(command)
    CommandResult.new(command, status.exitstatus, output, error)
  end

  class << self
    private

    # Checks if the given executable exists. If it does not exists,
    # an error message will be displayed and the program will exit.
    # Based on https://stackoverflow.com/a/5471032
    def find(executable)
      exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each do |ext|
          exe = File.join(path, "#{executable}#{ext}")
          return exe if File.executable?(exe) && !File.directory?(exe)
        end
      end
      Common.error("'#{executable}' was not found in PATH.")
    end
  end
end
