# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Helpers
        # Checks whether fields from a given source that will be mapped into a repeatable field group, have
        #   the same number of values
        #
        # Even/good:
        #
        # ```
        # {
        #   a_foo: 'afoo|aaa',
        #   a_bar: '%NULLVALUE%|abar'
        #   a_baz: 'a|baz'
        # }
        #
        # Uneven/bad:
        #
        # ```
        # {
        #   a_foo: 'afoo|aaa',
        #   a_bar: 'abar'
        #   a_baz: 'a|baz'
        # }
        class ValhashFieldEvennessChecker
          class << self
            def call(valhash)
              self.new(valhash).call
            end
          end

          # @param valhash [Hash] with the following structure:
          #
          # ```
          # {
          #   foo: {
          #     a: %w[a f],
          #     b: %w[bf],
          #     c: ['%NULLVALUE%'],
          #     d: %w[d f],
          #     e: ['%NULLVALUE%']
          #   },
          #   bar: {
          #     a: %w[a],
          #     b: %w[b],
          #     c: %w[c],
          #     d: ['%NULLVALUE%'],
          #     e: ['%NULLVALUE%']
          #   }
          # }
          # ```
          def initialize(valhash)
            @valhash = valhash
          end

          def call
            sources = valhash.first[1].keys
            checked = sources.map{ |source| is_even?(source) }
            return :even if checked.all?(true)

            checked.reject{ |result| result == true }
          end
          
          private

          attr_reader :valhash

          def is_even?(source)
            chk = valhash.map{ |_target, sources| sources[source].compact.length }
              .uniq
            return true if chk.length == 1

            source
          end
        end
      end
    end
  end
end
