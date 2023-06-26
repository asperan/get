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

module TestLibrary
  EOL_STATUS = 'eol'.freeze
  BRANCHES_REGEX = %r{(<script.*(?=id="branches\.json").*>\n)([\s\[\]\w{}":.,\-]*)(</script>)}
  TEST_IMAGE_BASE_NAME = 'test_get-ruby'.freeze

  class AvailableVersion
    attr_reader :major_minor, :status

    def initialize(major_minor, status)
      @major_minor = major_minor
      @status = status
    end

    def docker_ref
      @major_minor + (@status == 'preview' ? '-rc' : '')
    end
  end

  class NamedResult
    attr_reader :name, :output, :error, :status

    def initialize(name, output, error, status)
      @name = name
      @output = output
      @error = error
      @status = status
    end
  end

  def warn_and_exit(message, status = 1)
    warn(message)
    exit(status)
  end

  def maintained_ruby_versions
    page, error, status = Open3.capture3('curl', '-sS', 'https://www.ruby-lang.org/en/downloads/branches/')
    warn_and_exit "Failed to retrieve branch page: #{error}" if status.exitstatus.positive?
    match_result = page.match(BRANCHES_REGEX)
    warn_and_exit 'Failed to extract Ruby versions' if match_result.nil? || match_result[2].nil?
    JSON.parse(match_result[2])
        .reject { |specs| specs['status'] == EOL_STATUS }.map do |specs|
      AvailableVersion.new(specs['name'], specs['status'])
    end
  rescue JSON::ParserError => e
    warn_and_exit "Failed to parse JSON: '#{e.message}'"
  end

  def pwd_root_of_project?
    Dir.new(Dir.pwd).children.include?('get.gemspec')
  end

  def build_image(ruby_version)
    image_name = "#{TEST_IMAGE_BASE_NAME}#{ruby_version.docker_ref}"
    output, error, status = Open3.capture3('docker', 'build',
                                           '--target', 'test',
                                           '-t', image_name.to_s,
                                           '--build-arg', "RUBY_VERSION=#{ruby_version.docker_ref}",
                                           '.')
    NamedResult.new(image_name, output, error, status.exitstatus)
  end

  def formatted_build_error(image_name, error)
    <<~ERROR
      Failed to build image #{image_name}:
      =========== ERROR MESSAGE ===========
      #{error}
      =========== END ERROR MESSAGE ===========\n
    ERROR
  end

  def built_images(versions_to_build)
    build_results = versions_to_build.map { |v| build_image(v) }
    failed_builds = build_results.select { |r| r.status.positive? }
    unless failed_builds.empty?
      failed_builds.each { |f| puts formatted_build_error(f.name, f.error) }
      warn_and_exit 'Failed to build some images: see above for error messages'
    end
    puts 'Image builds completed successfully'
    build_results.map(&:name)
  end

  def full_container_name(image_name, test_branch)
    "#{image_name}-#{test_branch.gsub('/', '-')}"
  end

  def start_container(image_name, test_branch)
    output, error, status = Open3.capture3('docker', 'run',
                                           '--name', full_container_name(image_name, test_branch),
                                           '--env', "TEST_BRANCH=#{test_branch}",
                                           image_name)
    NamedResult.new(full_container_name(image_name, test_branch), output, error, status)
  end

  def remove_container(image_name, test_branch)
    Open3.capture3('docker', 'container', 'rm', full_container_name(image_name, test_branch))
  end

  def remove_image(image_name)
    Open3.capture3('docker', 'image', 'rm', image_name)
  end
end
