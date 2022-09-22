# frozen_string_literal: true

require 'bundler/setup'
Bundler.require(:tools)

# This needs to be the very first thing in this file
require 'simplecov'
SimpleCov.start do
  enable_coverage :branch
end

require_relative './helpers'
require 'kiba/extend'

RSpec.configure do |config|
  config.include Helpers
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
