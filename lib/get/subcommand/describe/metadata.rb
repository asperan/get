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

# Module with methods to handle tag metadata.
#
# To add a new metadata type, create a new method and link it to a symbol.
module MetadataHandler
  def compute_metadata(metadata_specs)
    requested_metadata = metadata_specs.split(',')
    unless requested_metadata.all? { |element| metadata_computers.include?(element.to_sym) }
      Common.error('Some of the metadata requested are not supported')
    end
    requested_metadata.map { |element| metadata_computers[element.to_sym].call }.join('-')
  end

  private

  def last_commit_sha
    `git --no-pager log -n 1 --pretty=%h`.strip
  end

  def current_date
    Time.now.strftime('%0Y%0m%0d')
  end

  def metadata_computers
    @metadata_computers ||= {
      sha: proc { last_commit_sha },
      date: proc { current_date },
    }
  end
end
