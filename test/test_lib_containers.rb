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
require_relative './test_lib_images'

module ContainerLifecycleHandler
  IMAGE_BRANCH_SEPARATOR = '_'.freeze
  BRANCH_SLASH_SUBSTITUTION = '.'.freeze

  def full_container_name(image_name, test_branch)
    "#{image_name}#{IMAGE_BRANCH_SEPARATOR}#{test_branch.gsub('/', BRANCH_SLASH_SUBSTITUTION)}"
  end

  def start_container(image_name, test_branch)
    output, error, status = Open3.capture3('docker', 'run',
                                           '--name', full_container_name(image_name, test_branch),
                                           '--env', "TEST_BRANCH=#{test_branch}",
                                           image_name)
    TestCommons::NamedResult.new(full_container_name(image_name, test_branch), output, error, status.exitstatus)
  end

  def remove_container(full_container_name)
    Open3.capture3('docker', 'container', 'rm', full_container_name)
  end

  def start_containers_from_images(images, test_branches)
    images.map { |i| test_branches.map { |b| start_container(i, b) } }
          .flatten
          .tap { |containers| containers.each { |c| print_container_result(c) } }
          .each { |c| remove_container(c.name) }
  end

  def print_container_result(container)
    formatted_name = container.name
                              .delete_prefix(ImageLifecycleHandler::TEST_IMAGE_BASE_NAME)
                              .split(IMAGE_BRANCH_SEPARATOR)
                              .tap { |parts| parts[1].gsub!(BRANCH_SLASH_SUBSTITUTION, '/') }
                              .then { |parts| "[ruby #{parts[0]}] #{parts[1]}" }
    if container.status.positive?
      puts "ERROR: #{formatted_name}\n#{failed_container_log(container)}"
    else
      puts "OK: #{formatted_name}"
    end
  end

  def failed_container_log(container_result)
    <<~LOG
      =========== CONTAINER '#{container_result.name}' LOG ===========
      #{container_result.error.strip}
      =========== END OF LOG ===========\n\n
    LOG
  end
end
