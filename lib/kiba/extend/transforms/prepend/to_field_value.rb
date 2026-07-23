# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Prepend
        # Adds the specified value to the specified field
        #
        # If target field value is blank, it is left blank
        #
        # @example Treated as single value (default)
        #   # Used in pipeline as:
        #   # transform Prepend::ToFieldValue, field: :name, value: 'aka: '
        #
        #   xform = Prepend::ToFieldValue.new(field: :name, value: 'aka: ')
        #   input = [
        #       {name: 'Weddy'},
        #       {name: 'Kernel|Zipper'},
        #       {name: nil},
        #       {name: ''}
        #     ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #       {name: 'aka: Weddy'},
        #       {name: 'aka: Kernel|Zipper'},
        #       {name: nil},
        #       {name: ''}
        #     ]
        #   expect(result).to eq(expected)
        #
        # @example Treated as multivalue
        #   # Used in pipeline as:
        #   # transform Prepend::ToFieldValue, field: :name, value: 'aka: ',
        #   #   delim: '|'
        #
        #   xform = Prepend::ToFieldValue.new(field: :name, value: 'aka: ',
        #     delim: '|')
        #   input = [
        #       {name: 'Weddy'},
        #       {name: 'Kernel|Zipper'},
        #       {name: nil},
        #       {name: ''}
        #     ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #       {name: 'aka: Weddy'},
        #       {name: 'aka: Kernel|aka: Zipper'},
        #       {name: nil},
        #       {name: ''}
        #     ]
        #   expect(result).to eq(expected)
        class ToFieldValue
          # @param field [Symbol] The field to prepend to
          # @param value [String] The value to be prepended
          # @param delim [NilValue, String] for splitting value if `multival`
          def initialize(field:, value:, delim: nil)
            @field = field
            @value = value
            @delim = delim
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            fieldval = row.fetch(field, nil)
            return row if fieldval.blank?

            fieldvals = delim ? fieldval.split(delim) : [fieldval]
            row[field] = fieldvals.map do |fieldval|
              "#{value}#{fieldval}"
            end.join(delim)
            row
          end

          private

          attr_reader :field, :value, :delim
        end
      end
    end
  end
end
