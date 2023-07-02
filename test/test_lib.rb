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

require 'json'
require_relative './test_lib_commons'
require_relative './test_lib_images'
require_relative './test_lib_containers'

module TestLibrary
  include ImageLifecycleHandler
  include ContainerLifecycleHandler
  include TestCommons

  EOL_STATUS = 'eol'.freeze
  BRANCHES_REGEX = %r{(<script.*(?=id="branches\.json").*>\n)([\s\[\]\w{}":.,\-]*)(</script>)}

  def maintained_ruby_versions
    page, error, status = Open3.capture3('curl', '-sS', 'https://www.ruby-lang.org/en/downloads/branches/')
    warn_and_exit "Failed to retrieve branch page: #{error}" if status.exitstatus.positive?
    match_result = page.match(BRANCHES_REGEX)
    warn_and_exit 'Failed to extract Ruby versions' if match_result.nil? || match_result[2].nil?
    JSON.parse(match_result[2])
        .reject { |specs| specs['status'] == EOL_STATUS }
        .map { |specs| AvailableVersion.new(specs['name'], specs['status']) }
  rescue JSON::ParserError => e
    warn_and_exit "Failed to parse JSON: '#{e.message}'"
  end

  def pwd_root_of_project?
    Dir.new(Dir.pwd).children.include?('get.gemspec')
  end

  def test_branches(test_repo_url)
    branches, error, status = Open3.capture3('git', 'ls-remote', '--heads', "#{test_repo_url}")
    if status.exitstatus.positive?
      warn_and_exit "Failed to retrieve test branches: #{error}"
    else
      branches
        .split("\n")
        .map { |b| b.split("\t").last.delete_prefix("refs/heads/") }
        .reject { |b| b == 'main' }
    end
  end
end
