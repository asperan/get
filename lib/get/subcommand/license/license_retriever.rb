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

require 'highline'
require_relative '../../commons/http_client'

# The retrieving module for licenses. It can gather licenses online (from https://choosealicense.com/appendix/)
# or offline (from a predefined subset of licenses).
module Retriever
  BASE_OFFLINE_LICENSE_PATH = "#{File.dirname(File.expand_path(__FILE__))}/offline_licenses".freeze
  BASE_ONLINE_LICENSE_URI = 'https://choosealicense.com'

  Common.module_instance_value(self, 'cli', 'HighLine.new')
  Common.add_module_self_reference(self)

  def ask_for_license(offline)
    @offline = offline
    list = if @offline
             offline_license_list
           else
             online_license_list
           end

    MOD_REF.cli.puts 'Choose which license you want to use:'
    choice = MOD_REF.cli.choose do |menu|
      menu.flow = :column_down
      menu.prompt = ''
      list.each { |element| menu.choice(element) }
    end

    if @offline
      offline_license_text(choice)
    else
      online_license_text(choice)
    end
  end

  private

  def offline_license_list
    Dir.children(BASE_OFFLINE_LICENSE_PATH)
  end

  def online_license_list
    @online_licenses = {}
    response = HTTPClient.instance.http_get_request("#{BASE_ONLINE_LICENSE_URI}/appendix/")
    if response.is_a?(Net::HTTPSuccess)
      response.body
              .strip
              .lines
              .select { |line| line.include?('<th scope="row">') }
              .each do |element|
        match_result = element.match(%r{<a href="(.*)">(.*)</a>})
        @online_licenses[match_result[2]] = match_result[1]
      end
      @online_licenses.keys
    else
      warning_message = 'WARNING: Unable to retrieve list of online licenses ' \
                        "(cause: #{HTTPClient.instance.response_error_message(response)}), " \
                        'falling back to offline ones.'
      puts warning_message
      @offline = true
      offline_license_list
    end
  end

  def offline_license_text(license)
    File.read("#{BASE_OFFLINE_LICENSE_PATH}/#{license}/LICENSE")
  end

  def online_license_text(license)
    response = HTTPClient.instance.http_get_request("#{BASE_ONLINE_LICENSE_URI}#{@online_licenses[license]}")
    if response.is_a?(Net::HTTPSuccess)
      match_result = response.body.match(%r{<pre id="license-text">(.*)</pre>}m)
      if match_result[1].nil?
        Common.error 'Invalid license text'
      else
        match_result[1]
      end
    else
      error_message = 'Failed to retrieve the license text ' \
                      "(cause: #{HTTPClient.instance.response_error_message(response)})."
      Common.error error_message
    end
  end
end
