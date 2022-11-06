# frozen_string_literal: true

require 'bundler/setup'
require "bundler/gem_tasks"
require "rake/testtask"
require 'rubocop/rake_task'

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/test_*.rb"]
end

RuboCop::RakeTask.new(:check_style) do |task|
  task.patterns = ['lib/**/*.rb']
  task.fail_on_error = false
end

task default: :test

# Generation of './lib/get/version.rb' file
BEGIN {
  begin
    require_relative 'lib/get/version'
    exist_version_file = true
  rescue LoadError => e
    exist_version_file = false
  end

  current_version = if exist_version_file
    Get::VERSION
  else
    # This version is semantically incorrect on purpose to force
    # the regeneration of the file if it does not exist
    '0.0.1'
  end

  def calculate_semantic_version
    '0.1.0'
  end

  def regenerate_version_file
    version_file = File.open(
      File.expand_path(__dir__) + '/lib/get/version.rb',
      File::CREAT | File::WRONLY | File::TRUNC
    )
    license_header = ''
    version_file << "#{license_header}" \
                    "# frozen_string_literal: true\n" \
                    "\n" \
                    "module Get\n" \
                    "  VERSION = '#{calculate_semantic_version}'\n" \
                    "end\n"
  end

  if Gem::Version.new(current_version) < Gem::Version.new(calculate_semantic_version)
    regenerate_version_file
  end
}
