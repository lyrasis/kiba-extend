# frozen_string_literal: true

require "psych"

module Kiba
  module Extend
    module JobTest
      class ConfigFilePrepper
        # @param path [String] to .yml config file
        def initialize(path)
          @path = path
        end

        # @return [Array<Hash>]
        def call
          set_job
          testclasses
        end

        private

        attr_reader :path, :job

        def yml = @yml ||= Psych.parse_file(path)
          .children
          .first
          .children

        def set_job
          key = yml.shift
          unless key.value == "job"
            fail("Missing or misplaced `job` key in #{path}")
          end

          val = yml.shift
          @job = val.value.to_sym
        end

        def testclasses
          key = yml.shift
          unless key.value == "testdefs"
            fail("Missing or misplaced `testdefs` key in #{path}")
          end

          yml.shift
            .children
            .map { |nodes| TestclassPrepper.new(nodes).call }
            .flatten
            .map { |cfg| cfg.merge({loc: loc(cfg[:srcline]), job: job}) }
        end

        def loc(srcline) = [path, srcline].compact.join(":")
      end
    end
  end
end
