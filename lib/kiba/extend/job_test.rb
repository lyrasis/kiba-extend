# frozen_string_literal: true

module Kiba
  module Extend
    # Convenience methods and settings related to job testing.

    # Job testing is a way to set up tests of individual data values in the
    #   output of a specific job in your project. This helps catch situations
    #   where changes made in or outside of that job are causing unexpected
    #   results.
    module JobTest
      module_function

      extend Dry::Configurable

      # @return [nil, String] path to directory containing .yml files of job
      #   test config
      setting :job_tests_dir_path,
        reader: true,
        default: nil,
        constructor: ->(default) do
          return default unless default

          File.expand_path(default)
        end
    end
  end
end
