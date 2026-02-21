# frozen_string_literal: true

module Kiba
  module Extend
    module JobTest
      class JobTestsRunner
        # @param job [Symbol]
        # @param tests [Array<Hash>]
        def initialize(job, tests)
          @job = job
          @tests = tests
          @status = :ok
        end

        def call
          return [] if tests.empty?
          set_path

          return tests if status == :error
          return tests unless generate_output

          set_job_data
          run_tests if status == :ok
          tests
        end

        private

        attr_reader :job, :tests, :status, :job_data

        def set_path
          entry = Kiba::Extend.registry.resolve(job)
          tests.each { |t| t[:path] = entry[:path] }
        rescue
          @status = :error
          msg = "#{job} job does not exist in registry"
          tests.map! do |t|
            t.merge({got: errmsg(t, msg), status: :failure})
          end
        end

        def generate_output
          res = Kiba::Extend::Job.output?(job)
          return true if res

          @status = :error
          msg = "There is no output for the #{job} job"
          tests.map! do |t|
            t.merge({got: errmsg(t, msg), status: :failure})
          end
          nil
        end

        def errmsg(test, msg) = [test[:loc], msg].compact.join(": ")

        def set_job_data
          test = tests.first
          klass = test[:test]
          @job_data = Kiba::Extend::JobTest.const_get(klass)
            .new(test)
            .job_data
        rescue
          @status = :error
          msg = "No #{klass} defined for test defined at #{test[:loc]}"
          tests.map! do |t|
            t.merge({got: errmsg(t, msg), status: :failure})
          end
        end

        def run_tests = tests.map! { |t| Runner.new(t, job_data).call }
      end
    end
  end
end
