# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Rename
        # rubocop:disable Layout/LineLength

        # Renames multiple fields at once, given a fieldmap where key
        #   is `from` field and value is `to` field
        #
        # This transform works by creating a {Rename::Field} transform for each
        #   key/value pair specified in `fieldmap`, so see {Rename::Field} for
        #   examples demonstrating edge case behavior.
        #
        #
        # @example
        #   # Used in pipeline as:
        #   # transform Rename::Fields, fieldmap: {
        #   #   name: :appellation,
        #   #   sex: :gender,
        #   #   color: :color
        #   # }
        #   xform = Rename::Fields.new(fieldmap: {
        #     name: :appellation,
        #     sex: :gender,
        #     color: :color
        #   })
        #   input = [
        #     {name: "Weddy", sex: "m", color: "pearl gray, greater, pied"},
        #     {name: "Kernel", sex: "f", color: "buff dundotte"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {appellation: "Weddy", gender: "m", color: "pearl gray, greater, pied"},
        #     {appellation: "Kernel", gender: "f", color: "buff dundotte"},
        #   ]
        #   expect(result).to eq(expected)
        #
        #
        # @since 2.8.0
        class Fields
          # rubocop:enable Layout/LineLength
          # @param fieldmap [Hash(Symbol => Symbol)] Keys are the `from` fields;
          #   values are the `to` fields
          def initialize(fieldmap:)
            @fieldmap = fieldmap
            @renamers = fieldmap.map do |from, to|
              Rename::Field.new(from: from, to: to)
            end
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            renamers.each { |renamer| renamer.process(row) }
            row
          end

          private

          attr_reader :fieldmap, :renamers
        end
      end
    end
  end
end
