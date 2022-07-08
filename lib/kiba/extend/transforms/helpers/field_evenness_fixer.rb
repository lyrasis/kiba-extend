# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Helpers
        # Adds %NULLVALUE%s to end of source fields to achieve evenness
        #
        # Uneven/bad:
        #
        # ```
        # {
        #   a_foo: 'afoo|aaa',
        #   a_bar: 'abar'
        #   a_baz: 'a|baz'
        # }
        #
        # Becomes:
        #
        # ```
        # {
        #   a_foo: 'afoo|aaa',
        #   a_bar: 'abar|%NULLVALUE%'
        #   a_baz: 'a|baz'
        # }
        class FieldEvennessFixer
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
            sources.each{ |source| even(source) }
            valhash
          end
          
          private

          attr_reader :valhash

          def even(source)
            max = max_for(source)
            valhash.keys.each{ |target| pad_source_for_target(target, source, max) }
          end
          
          def max_for(source)
            valhash.map{ |_target, sources| sources[source].compact.length }
              .max
          end

          def pad_source_for_target(target, source, max)
            srcval = valhash[target][source]
            return if srcval.length == max
            
            diff = max - srcval.length
            diff.times{ srcval << '%NULLVALUE%' }
          end
        end
      end
    end
  end
end
