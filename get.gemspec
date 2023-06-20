# frozen_string_literal: true

require_relative 'lib/get/version'

class Gem::Specification
  def included_files
    excluded_files = []

    (Dir['lib/**/*'] + Dir['bin/*'])
      .filter { |element| !excluded_files.include?(element) }
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
end

Gem::Specification.new do |spec|
  spec.name = 'git_toolbox'
  spec.version = GET_VERSION
  spec.authors = spec.retrieve_authors
  spec.email = spec.retrieve_emails
  spec.license = 'LGPL-3.0-or-later'

  spec.summary = 'Git Enhancement Toolbox'
  spec.homepage = 'https://github.com/asperan/get'
  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/asperan/get'
  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = spec.included_files
  spec.bindir = 'bin'
  spec.executables = ['get']
  spec.require_paths = ['lib']

  spec.add_dependency 'highline', '~> 2.0.3'
  spec.add_dependency 'optimist', '~> 3.0', '>= 3.0.1'
  spec.add_dependency 'singleton', '~> 0.1.1'
end
