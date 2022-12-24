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

# Git hooks regeneration
# rubocop:disable Style/BeginBlock
BEGIN {
  HOOKS = [
    {
      path: "./.git/hooks/pre-push",
      scripts: [
        <<~RUBOCOP,
          # Check style with rubocop
          exe/rubocop lib/
        RUBOCOP
        <<~VERSION,
          # Check if the version file is up to date
          VERSION_FILE="lib/get/version.rb"

          current_version=$(grep 'VERSION = ' "${VERSION_FILE}" | cut -d '=' -f 2 | tr -d "' ")
          described_version=$(exe/get describe | cut -d '+' -f 1)
  
          if [ "$current_version" = "$described_version" ]; then
            echo "Version file is up to date."
          else
            echo "Version file and actual version differs. Update the version file (and move the tag)."
          fi
        VERSION
      ],
    },
  ]

  shebang = '#!/bin/sh'

  license = <<~LICENSE
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
  LICENSE

  HOOKS.each do |element|
    hook_content = <<~CONTENT
      #{shebang}
      #{license}
      #{element[:scripts].join("\n")}
    CONTENT

    pre_hook_file = File::open(element[:path], File::RDONLY)
    old_hook_content = pre_hook_file.read()
    pre_hook_file.close()

    if (old_hook_content.strip != hook_content.strip)
      File::open(element[:path], File::WRONLY | File::TRUNC) do |file|
        file.write(hook_content)
      end
      puts "Hook '#{element[:path]}' regenerated."
    end
  end
}
# rubocop:enable Style/BeginBlock
