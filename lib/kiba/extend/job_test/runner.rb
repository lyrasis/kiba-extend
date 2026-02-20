# frozen_string_literal: true

module Kiba
  module Extend
    module JobTest
      class Runner
        # @param config [Hash]
        def initialize(config, srcfile = nil, srcline = nil)
          @config = config
          @srcfile = srcfile
          @srcline = srcline
          @job = config[:job]
          @error_msg = nil
        end

        def call
          set_testclass
          set_path unless error_msg
          generate_output unless error_msg
          test = generate_test unless error_msg
          return unrunnable_result if error_msg

          test.result
        end

        private

        attr_reader :config, :srcfile, :srcline, :testclass, :job, :error_msg

        def location
          return nil if !srcfile && !srcline

          [srcfile, srcline].join(":")
        end

        def unrunnable_result
          config[:status] = :failure
          config[:got] = [location, error_msg].compact.join(":")
          config
        end

        def set_testclass
          klass = config[:test]
          @testclass = Kiba::Extend::JobTest.const_get(klass)
        rescue
          @error_msg = "No Kiba::Extend::JobTest::#{klass} job test "\
          "class is defined"
        end

        def set_path
          entry = Kiba::Extend.registry.resolve(job)
          config[:path] = entry[:path]
        rescue
          @error_msg = "#{job} job does not exist in registry"
        end

        def generate_output
          res = Kiba::Extend::Job.output?(job)
          return if res

          @error_msg = "There is no output for the #{job} job"
        end

        def generate_test
          testclass.new(config)
        rescue => err
          @error_msg = err.message
        end
      end
    end
  end
end
