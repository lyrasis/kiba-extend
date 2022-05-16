# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Rename
        # Renames multiple fields at once, given a fieldmap where key is `from` field and value is `to` field
        #
        # # Examples
        #
        # Input rows:
        #
        # ```
        # {name: 'Weddy', sex: 'm'},
        # {name: 'Kernel', sex: 'f'}
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform Rename::Fields, fieldmap: {name: :appellation, sex: :gender}
        # ```
        #
        # Results in:
        #
        # ```
        # {appellation: 'Weddy', gender: 'm'},
        # {appellation: 'Kernel', gender: 'f'}
        # ```
        #
        # @since 2.8.0
        class Fields
          # @param fieldmap [Hash(Symbol => Symbol)] Keys are the `from` fields; values are the `to` fields
          def initialize(fieldmap:)
            @fieldmap = fieldmap
            @renamers = fieldmap.map{ |from, to| Rename::Field.new(from: from, to: to) }
          end

          # @private
          def process(row)
            renamers.each{ |renamer| renamer.process(row) }
            row
          end

          private

          attr_reader :fieldmap, :renamers
        end
      end
    end
  end
end
