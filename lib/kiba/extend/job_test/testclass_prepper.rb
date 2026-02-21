# frozen_string_literal: true

module Kiba
  module Extend
    module JobTest
      class TestclassPrepper
        # @param nodes [Array<Psych::Nodes::Mapping>]
        def initialize(nodes)
          @yml = nodes.children
        end

        # @return [Array<Hash>]
        def call
          set_testclass
          tests
        end

        private

        attr_reader :yml, :testclass

        def set_testclass
          key = yml.shift
          unless key.value == "testclass"
            fail("Missing or misplaced `testclass` key in #{path}")
          end

          val = yml.shift
          @testclass = val.value
        end

        def tests
          key = yml.shift
          unless key.value == "tests"
            fail("Missing or misplaced `tests` key in #{path}")
          end

          yml.shift
            .children
            .map { |nodes| TestPrepper.new(nodes).call }
            .each { |config| config[:test] = testclass }
        end
      end
    end
  end
end
