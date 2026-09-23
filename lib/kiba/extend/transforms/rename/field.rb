# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Rename
        # Renames one field
        #
        # ## Example notes
        #
        # ### 1 - :from field exists
        #
        # :from field renamed to :to field. Not much to see here.
        #
        # ### 2 - :to field already exists
        #
        # :sex is renamed to :gender, overwriting the existing value
        #   of :gender (unknown) with value of :sex (m). The transform
        #   emits a warning about this unless you
        #   suppress_overwrite_warnings
        #
        # ### 3 - :from field does not exist
        #
        # Row is passed through unchanged, and the transform emits a
        #   warning about not being able to rename a field that
        #   doesn't exist, unless you suppress_missing_key_warnings
        #
        # ### 4 - :from and :to field are the same
        #
        # This seems like a real weird edge case from the perspective
        #   of defining transforms manually, but it can happen when
        #   transform definitions are programmatically generated from
        #   configuration.
        #
        # @example 1 - :from field exists
        #   # Used in pipeline as:
        #   # transform Rename::Field,
        #   #   from: :sex,
        #   #   to: :gender
        #   xform = Rename::Field.new(
        #     from: :sex,
        #     to: :gender
        #   )
        #   input = [
        #     {name: "Weddy", sex: "m", color: "pearl gray, greater, pied"},
        #     {name: "Kernel", sex: "f", color: "buff dundotte"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {name: "Weddy", gender: "m", color: "pearl gray, greater, pied"},
        #     {name: "Kernel", gender: "f", color: "buff dundotte"},
        #   ]
        #   expect(result).to eq(expected)
        #
        # @example 2 - :to field already exists
        #   # Used in pipeline as:
        #   # transform Rename::Field,
        #   #   from: :sex,
        #   #   to: :gender
        #   xform = Rename::Field.new(
        #     from: :sex,
        #     to: :gender
        #   )
        #   input = [
        #     {name: "Weddy", sex: "m", gender: "unknown"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {name: "Weddy", gender: "m"}
        #   ]
        #   expect(xform.send(:single_warnings)).to include(
        #     "Renaming `sex` to `gender` overwrites existing `gender` "\
        #     "field data"
        #   )
        #   expect(result).to eq(expected)
        #
        # @example 2b - :to field already exists, warning suppressed
        #   # Used in pipeline as:
        #   # transform Rename::Field,
        #   #   from: :sex,
        #   #   to: :gender,
        #   #   suppress_overwrite_warnings: true
        #   xform = Rename::Field.new(
        #     from: :sex,
        #     to: :gender,
        #     suppress_overwrite_warnings: true
        #   )
        #   input = [
        #     {name: "Weddy", sex: "m", gender: "unknown"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {name: "Weddy", gender: "m"}
        #   ]
        #   expect(xform.send(:single_warnings)).not_to include(
        #     "Renaming `sex` to `gender` overwrites existing `gender`"\
        #     "field data"
        #   )
        #   expect(result).to eq(expected)
        #
        # @example 3 - :from field does not exist
        #   # Used in pipeline as:
        #   # transform Rename::Field,
        #   #   from: :sex,
        #   #   to: :gender
        #   xform = Rename::Field.new(
        #     from: :sex,
        #     to: :gender
        #   )
        #   input = [
        #     {name: "Weddy", gender: "unknown"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {name: "Weddy", gender: "unknown"}
        #   ]
        #   expect(xform.send(:single_warnings)).to include(
        #     "Cannot rename field: `sex` does not exist in row"
        #   )
        #   expect(result).to eq(expected)
        #
        # @example 3b - :from field does not exist, warnings suppressed
        #   # Used in pipeline as:
        #   # transform Rename::Field,
        #   #   from: :sex,
        #   #   to: :gender,
        #   #   suppress_missing_key_warnings: true
        #   xform = Rename::Field.new(
        #     from: :sex,
        #     to: :gender,
        #     suppress_missing_key_warnings: true
        #   )
        #   input = [
        #     {name: "Weddy", gender: "unknown"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {name: "Weddy", gender: "unknown"}
        #   ]
        #   expect(xform.send(:single_warnings)).not_to include(
        #     "Cannot rename field: `sex` does not exist in row"
        #   )
        #   expect(result).to eq(expected)
        #
        # @example 4 - :from and :to field are the same
        #   # Used in pipeline as:
        #   # transform Rename::Field,
        #   #   from: :gender,
        #   #   to: :gender
        #   xform = Rename::Field.new(
        #     from: :gender,
        #     to: :gender
        #   )
        #   input = [
        #     {name: "Weddy", gender: "unknown"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {name: "Weddy", gender: "unknown"}
        #   ]
        #   expect(result).to eq(expected)
        class Field
          include SingleWarnable

          # @param from [Symbol] current field name
          # @param to [Symbol] target field name
          # @param suppress_missing_key_warnings [Boolean]
          # @param suppress_overwrite_warnings [Boolean]
          def initialize(from:, to:,
            suppress_missing_key_warnings: false,
            suppress_overwrite_warnings: false)
            @from = from
            @to = to
            @suppress_missing_key_warnings = suppress_missing_key_warnings
            @suppress_overwrite_warnings = suppress_overwrite_warnings
            setup_single_warning unless suppress_missing_key_warnings &&
              suppress_overwrite_warnings
          end

          # @param row [Hash{ Symbol => String, nil }]
          # @return [Hash{ Symbol => String, nil }]
          def process(row)
            return row if from == to

            unless row.key?(from)
              unless suppress_missing_key_warnings
                add_single_warning("Cannot rename field: `#{from}` does not "\
                                   "exist in row")
              end

              return row
            end

            if row.key?(to) && !suppress_overwrite_warnings
              add_single_warning("Renaming `#{from}` to `#{to}` overwrites "\
                                 "existing `#{to}` field data")
            end

            row[to] = row.fetch(from)
            row.delete(from)
            row
          end

          private

          attr_reader :from, :to, :suppress_missing_key_warnings,
            :suppress_overwrite_warnings
        end
      end
    end
  end
end
