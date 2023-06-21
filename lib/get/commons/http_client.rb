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

require 'net/http'
require 'uri'

# Client HTTP which allows to perform GET request and follow redirections.
class HTTPClient
  include Singleton

  # Number of attempts to try when following a redirection link.
  MAX_ATTEMPTS = 10

  # Perform a get request to an address, following the redirections at most MAX_ATTEMPTS times.
  def http_get_request(address)
    uri = URI.parse(address)

    # Code based on https://shadow-file.blogspot.com/2009/03/handling-http-redirection-in-ruby.html
    attempts = 0
    until attempts >= MAX_ATTEMPTS
      attempts += 1

      resp = build_http(uri)
             .request(Net::HTTP::Get.new(uri.path == '' ? '/' : uri.path))
      return resp if resp.is_a?(Net::HTTPSuccess) || resp.header['location'].nil?

      uri = updated_uri(uri, resp.header['location'])
    end
    nil
  end

  def response_error_message(response)
    if response.nil?
      'too many redirections'
    else
      "#{response.code} #{response.message}"
    end
  end

  private

  def build_http(uri)
    Net::HTTP.new(uri.host, uri.port)
             .tap { |http| http.open_timeout = 10 }
             .tap { |http| http.read_timeout = 10 }
             .tap do |http|
      if uri.instance_of? URI::HTTPS
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
    end
  end

  def updated_uri(old_uri, location)
    URI.parse(location).then do |value|
      if value.relative?
        old_uri + location
      else
        value
      end
    end
  end
end
