# frozen_string_literal: true

require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rubocop/rake_task'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/test_*.rb']
end

RuboCop::RakeTask.new(:check_style) do |task|
  task.patterns = ['lib/**/*.rb']
  task.fail_on_error = false
end

# Check syntax for all lib source files
task :check_syntax do |task|
  source_files = FileList['lib/**/*.rb']
  source_files.each do |element|
    output = `ruby -c #{element} 2>&1`.chomp
    if output == 'Syntax OK'
      puts "#{element}: OK"
    else
      puts <<~OUTPUT
        --- Syntax errors for #{element} ---
        #{output}
        ----------------------#{'-' * element.length}----
      OUTPUT
    end
  end
end

# Run all the check tasks
task check: [:check_syntax, :check_style] do
end

task default: :test

# Generation of './lib/get/version.rb' file
# The generation must occur before the load of 'bundler/setup',
# so the block could be placed before the requires at the top
# of the file or in a BEGIN block. The latter has been chosen
# as it seemed the least style-impacting choice.
# rubocop:disable Style/BeginBlock
BEGIN {
  begin
    require_relative 'lib/get/version'
    exist_version_file = true
  rescue LoadError
    exist_version_file = false
  end

  current_version =
    if exist_version_file
      Get::VERSION
    else
      # This version is semantically incorrect on purpose to force
      # the regeneration of the file if it does not exist
      '0.0.1'
    end

  def calculate_semantic_version
    '0.1.0'
  end

  def license_header
    <<~HEADER
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
    HEADER
  end

  def generation_comments
    <<~GENCOM
      # This file is automatically generated by the Rakefile.
      # It must be tracked by git, but changes should be made via the Rakefile.
    GENCOM
  end

  def version_file_content
    <<~CONTENT
      # frozen_string_literal: true
      #{license_header}
      #{generation_comments}
      module Get
        VERSION = '#{calculate_semantic_version}'
      end
    CONTENT
  end

  def regenerate_version_file
    version_file = File.open(
      "#{File.expand_path(__dir__)}/lib/get/version.rb",
      File::CREAT | File::WRONLY | File::TRUNC
    )
    version_file << version_file_content
  end

  # Class String with a method to create a Gem::Version from self.
  class String
    def to_version
      Gem::Version.new(self)
    end
  end

  regenerate_version_file if
    current_version.to_version < calculate_semantic_version.to_version
}
# rubocop:enable Style/BeginBlock
