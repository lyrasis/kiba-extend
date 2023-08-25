# frozen_string_literal: true

require "bundler/setup"
Bundler.require(:tools)

# This needs to be the very first thing in this file
require "simplecov"
SimpleCov.start do
  enable_coverage :branch
end

require_relative "helpers"
require "kiba/extend"
require "dry/configurable/test_interface"

module Kiba
  module Extend
    enable_test_interface

    module Marc
      enable_test_interface
    end
  end
end

RSpec.configure do |config|
  config.include Helpers

  # random but deterministic test order
  config.order = :random
  Kernel.srand config.seed

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
    c.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_doubled_constant_names = true
    mocks.verify_partial_doubles = true
  end
end
