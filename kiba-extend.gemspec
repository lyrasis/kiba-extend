# frozen_string_literal: true

require_relative "lib/kiba/extend/version"

Gem::Specification.new do |spec|
  spec.name = "kiba-extend"
  spec.version = Kiba::Extend::VERSION
  spec.authors = ["Kristina Spurgin"]
  spec.email = ["kristina.spurgin@lyrasis.org"]

  spec.summary = "Extensions for Kiba ETL"
  spec.homepage = "https://github.com/lyrasis/kiba-extend"
  spec.license = "MIT"

  spec.required_ruby_version = ">=3.4.1"
  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the
  #   'allowed_push_host' to allow pushing to a single host or delete this
  #   section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/lyrasis/kiba-extend"
    spec.metadata["changelog_uri"] = "https://github.com/lyrasis/kiba-extend"
  else
    raise "RubyGems 2.0 or newer is required to protect against "\
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added
  #   into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(test|spec|features)/})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport"
  spec.add_dependency "bigdecimal"
  spec.add_dependency "amazing_print"
  spec.add_dependency "csv"
  spec.add_dependency "dry-configurable"
  # @todo 0.9.0 ?
  spec.add_dependency "dry-container", "~> 0"
  # @todo 4.0
  spec.add_dependency "kiba", "~> 4"
  # @todo 1.5
  spec.add_dependency "kiba-common", "~> 1"
  spec.add_dependency "marc", "~> 1.2"
  spec.add_dependency "measured"
  # @todo 1.2.1?
  spec.add_dependency "thor", "~> 1"
  # @todo can replace with stdlib?
  spec.add_dependency "xxhash", "~> 0"
  spec.add_dependency "zeitwerk", "~> 2.5"
end
