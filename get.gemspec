# frozen_string_literal: true

require_relative 'lib/get/version'

def source_files
  excluded_sources = []

  Dir.glob("#{File.expand_path(__dir__)}/lib/**/*.rb")
     .filter { |element| !excluded_sources.include?(element) }
end

def executable_list
  Dir.glob("#{File.expand_path(__dir__)}/bin/*")
end

def retrieve_authors
  ['Alex Speranza']
  # names = %x(`git log --pretty=%an || echo "" | sort --unique`)
  # puts names
end

def retrieve_emails
  ['alex.speranza@studio.unibo.it']
  # emails = %x(`git log --pretty=%ae || echo "" | sort --unique`)
  # puts emails
end

Gem::Specification.new do |spec|
  spec.name = 'get'
  spec.version = Get::VERSION
  spec.authors = retrieve_authors
  spec.email = retrieve_emails
  spec.license = 'LGPL-3.0-or-later'

  spec.summary = 'Git Enhancement Toolbox'
  spec.homepage = 'https://github.com/asperan/get'
  spec.required_ruby_version = '>= 2.6.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/asperan/get'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = source_files
  spec.bindir = 'bin'
  spec.executables = spec.name
  spec.require_paths = ['lib']

end
