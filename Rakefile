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
