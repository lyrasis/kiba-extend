# frozen_string_literal: true

module Kiba
  module Extend
    module JobTest
      class SuiteRunner
        # @param dir [String]
        def initialize(dir = JobTest.job_tests_dir_path)
          unless Dir.exist?(dir)
            fail("Cannot run job tests: #{dir} does not exist")
          end

          @dir = dir
        end

        def call
          results = run_tests
          if results.key?(:failure)
            results[:failure].each do |test|
              puts "\n"
              puts test[:got]
            end
            puts "\n\nFailures: #{results[:failure].length}"
          end
          if results.key?(:success)
            puts "Successes: #{results[:success].length}"
          end
        end

        def results = @results ||= run_tests

        private

        attr_reader :dir

        def tests_by_job = Dir.children(dir)
          .map { |f| ConfigFilePrepper.new(File.join(dir, f)).call }
          .flatten
          .group_by { |config| config[:job] }

        def run_tests
          tests_by_job.map do |job, tests|
            JobTestsRunner.new(job, tests).call
          end.flatten
            .group_by { |test| test[:status] }
        end
      end
    end
  end
end
