# frozen_string_literal: true

require_relative 'lib/kiba/extend/version'

Gem::Specification.new do |spec|
  spec.name          = 'kiba-extend'
  spec.version       = Kiba::Extend::VERSION
  spec.authors       = ['Kristina Spurgin']
  spec.email         = ['kristina.spurgin@lyrasis.org']

  spec.summary       = 'Extensions for Kiba ETL'
  spec.homepage      = 'https://github.com/lyrasis/kiba-extend'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>=2.7.3'
  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"

    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = 'https://github.com/lyrasis/kiba-extend'
    spec.metadata['changelog_uri'] = 'https://github.com/lyrasis/kiba-extend'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '~> 6.1.4'
  spec.add_dependency 'csv', '~> 3.0'
  spec.add_dependency 'dry-configurable', '~> 0.11'
  spec.add_dependency 'kiba', '~> 4.0.0'
  spec.add_dependency 'kiba-common', '~> 1.5.0'
  spec.add_dependency 'xxhash', '~> 0.4'

  spec.add_development_dependency 'bundler', '>= 1.17'
  spec.add_development_dependency 'pry', '~> 0.12.2'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 1.18.4'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.4.0'
end
