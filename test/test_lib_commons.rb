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

module TestCommons
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
end
