# frozen_string_literal: true

module Kiba
  module Extend
    module JobTest
      class Runner
        # @param config [Hash]
        def initialize(config, job_data = nil)
          @config = config
          @job_data = job_data
          @loc = config[:loc]
          @error_msg = nil
        end

        def call
          set_testclass
          test = generate_test unless error_msg
          return unrunnable_result if error_msg

          test.result
        end

        private

        attr_reader :config, :job_data, :loc, :error_msg, :testclass

        def unrunnable_result
          config[:status] = :failure
          config[:got] = [loc, error_msg].compact.join(":")
          config
        end

        def set_testclass
          klass = config[:test]
          @testclass = Kiba::Extend::JobTest.const_get(klass)
        rescue
          @error_msg = "No Kiba::Extend::JobTest::#{klass} job test "\
            "class is defined"
        end

        def generate_test
          testclass.new(config, job_data)
        rescue => err
          @error_msg = err.message
        end
      end
    end
  end
end
