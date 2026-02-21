# frozen_string_literal: true

module Kiba
  module Extend
    module JobTest
      class SuiteRunner
        # @param dir [String]
        def initialize(dir = JobTest.job_test_dir_path)
          unless Dir.exist?(dir)
            fail("Cannot run job tests: #{dir} does not exist")
          end

          @dir = dir
        end

        def call
          tests_by_job.map { |job, tests| JobTestsRunner.new(job, tests).call }
            .flatten
            .each do |test|
              next unless test[:status] == :failure

              puts "\n#{test[:loc]}"
              puts test[:desc]
              puts "Got: #{test[:got]}"
            end
        end

        private

        attr_reader :dir

        def tests_by_job = Dir.children(dir)
          .map { |f| ConfigFilePrepper.new(File.join(dir, f)).call }
          .flatten
          .group_by { |config| config[:job] }
      end
    end
  end
end
