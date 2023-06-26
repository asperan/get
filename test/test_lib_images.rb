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

require 'open3'
require_relative './test_lib_commons'

module ImageLifecycleHandler
  TEST_IMAGE_BASE_NAME = 'test_get-ruby'.freeze

  def build_image(ruby_version)
    image_name = "#{TEST_IMAGE_BASE_NAME}#{ruby_version.docker_ref}"
    output, error, status = Open3.capture3('docker', 'build',
                                           '--target', 'test',
                                           '-t', image_name.to_s,
                                           '--build-arg', "RUBY_VERSION=#{ruby_version.docker_ref}",
                                           '.')
    TestCommons::NamedResult.new(image_name, output, error, status.exitstatus)
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

  def remove_image(image_name)
    Open3.capture3('docker', 'image', 'rm', image_name)
  end
end
