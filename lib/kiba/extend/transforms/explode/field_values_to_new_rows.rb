# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Explode
        # @example Multival, without keeping nil or empty
        #   # Used in pipeline as:
        #   # transform Explode::FieldValuesToNewRows,
        #   #   fields: %i[child parent],
        #   #   target: :val,
        #   #   multival: true,
        #   #   sep: ";"
        #   xform = Explode::FieldValuesToNewRows.new(
        #     fields: %i[child parent],
        #     target: :val,
        #     multival: true,
        #     sep: ";"
        #   )
        #   input = [
        #     {id: 1, child: "a;b", parent: "c;d"},
        #     {id: 2, child: "a", parent: "b"},
        #     {id: 3, child: "", parent: "q"},
        #     {id: 4, child: "n", parent: nil},
        #     {id: 5, child: "", parent: nil},
        #     {id: 6, child: "p;", parent: ";z"},
        #     {id: 7, child: "m;;n", parent: "s"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {id: 1, val: "a"},
        #     {id: 1, val: "b"},
        #     {id: 1, val: "c"},
        #     {id: 1, val: "d"},
        #     {id: 2, val: "a"},
        #     {id: 2, val: "b"},
        #     {id: 3, val: "q"},
        #     {id: 4, val: "n"},
        #     {id: 6, val: "p"},
        #     {id: 6, val: "z"},
        #     {id: 7, val: "m"},
        #     {id: 7, val: "n"},
        #     {id: 7, val: "s"}
        #   ]
        #   expect(result).to eq(expected)
        # @example Multival, keeping nil
        #   # Used in pipeline as:
        #   # transform Explode::FieldValuesToNewRows,
        #   #   fields: %i[child parent],
        #   #   target: :val,
        #   #   multival: true,
        #   #   sep: ";",
        #   #   keep_nil: true
        #   xform = Explode::FieldValuesToNewRows.new(
        #     fields: %i[child parent],
        #     target: :val,
        #     multival: true,
        #     sep: ";",
        #     keep_nil: true
        #   )
        #   input = [
        #     {id: 1, child: "a;b", parent: "c;d"},
        #     {id: 2, child: "a", parent: "b"},
        #     {id: 3, child: "", parent: "q"},
        #     {id: 4, child: "n", parent: nil},
        #     {id: 5, child: "", parent: nil},
        #     {id: 6, child: "p;", parent: ";z"},
        #     {id: 7, child: "m;;n", parent: "s"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {id: 1, val: "a"},
        #     {id: 1, val: "b"},
        #     {id: 1, val: "c"},
        #     {id: 1, val: "d"},
        #     {id: 2, val: "a"},
        #     {id: 2, val: "b"},
        #     {id: 3, val: "q"},
        #     {id: 4, val: "n"},
        #     {id: 4, val: nil},
        #     {id: 5, val: nil},
        #     {id: 6, val: "p"},
        #     {id: 6, val: "z"},
        #     {id: 7, val: "m"},
        #     {id: 7, val: "n"},
        #     {id: 7, val: "s"}
        #   ]
        #   expect(result).to eq(expected)
        # @example Multival, keeping empty
        #   # Used in pipeline as:
        #   # transform Explode::FieldValuesToNewRows,
        #   #   fields: %i[child parent],
        #   #   target: :val,
        #   #   multival: true,
        #   #   sep: ";",
        #   #   keep_empty: true
        #   xform = Explode::FieldValuesToNewRows.new(
        #     fields: %i[child parent],
        #     target: :val,
        #     multival: true,
        #     sep: ";",
        #     keep_empty: true
        #   )
        #   input = [
        #     {id: 1, child: "a;b", parent: "c;d"},
        #     {id: 2, child: "a", parent: "b"},
        #     {id: 3, child: "", parent: "q"},
        #     {id: 4, child: "n", parent: nil},
        #     {id: 5, child: "", parent: nil},
        #     {id: 6, child: "p;", parent: ";z"},
        #     {id: 7, child: "m;;n", parent: "s"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {id: 1, val: "a"},
        #     {id: 1, val: "b"},
        #     {id: 1, val: "c"},
        #     {id: 1, val: "d"},
        #     {id: 2, val: "a"},
        #     {id: 2, val: "b"},
        #     {id: 3, val: ""},
        #     {id: 3, val: "q"},
        #     {id: 4, val: "n"},
        #     {id: 5, val: ""},
        #     {id: 6, val: "p"},
        #     {id: 6, val: ""},
        #     {id: 6, val: ""},
        #     {id: 6, val: "z"},
        #     {id: 7, val: "m"},
        #     {id: 7, val: ""},
        #     {id: 7, val: "n"},
        #     {id: 7, val: "s"}
        #   ]
        #   expect(result).to eq(expected)
        # @example Single val, without keeping nil or empty
        #   # Used in pipeline as:
        #   # transform Explode::FieldValuesToNewRows,
        #   #   fields: %i[child parent],
        #   #   target: :val,
        #   xform = Explode::FieldValuesToNewRows.new(
        #     fields: %i[child parent],
        #     target: :val,
        #   )
        #   input = [
        #     {id: 1, child: "a;b", parent: "c;d"},
        #     {id: 2, child: "a", parent: "b"},
        #     {id: 3, child: "", parent: "q"},
        #     {id: 4, child: "n", parent: nil},
        #     {id: 5, child: "", parent: nil},
        #     {id: 6, child: "p;", parent: ";z"},
        #     {id: 7, child: "m;;n", parent: "s"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {id: 1, val: "a;b"},
        #     {id: 1, val: "c;d"},
        #     {id: 2, val: "a"},
        #     {id: 2, val: "b"},
        #     {id: 3, val: "q"},
        #     {id: 4, val: "n"},
        #     {id: 6, val: "p;"},
        #     {id: 6, val: ";z"},
        #     {id: 7, val: "m;;n"},
        #     {id: 7, val: "s"}
        #   ]
        #   expect(result).to eq(expected)
        # @example Single val, keeping nil and empty
        #   # Used in pipeline as:
        #   # transform Explode::FieldValuesToNewRows,
        #   #   fields: %i[child parent],
        #   #   target: :val,
        #   #   keep_nil: true,
        #   #   keep_empty: true
        #   xform = Explode::FieldValuesToNewRows.new(
        #     fields: %i[child parent],
        #     target: :val,
        #     keep_nil: true,
        #     keep_empty: true
        #   )
        #   input = [
        #     {id: 1, child: "a;b", parent: "c;d"},
        #     {id: 2, child: "a", parent: "b"},
        #     {id: 3, child: "", parent: "q"},
        #     {id: 4, child: "n", parent: nil},
        #     {id: 5, child: "", parent: nil},
        #     {id: 6, child: "p;", parent: ";z"},
        #     {id: 7, child: "m;;n", parent: "s"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {id: 1, val: "a;b"},
        #     {id: 1, val: "c;d"},
        #     {id: 2, val: "a"},
        #     {id: 2, val: "b"},
        #     {id: 3, val: ""},
        #     {id: 3, val: "q"},
        #     {id: 4, val: "n"},
        #     {id: 4, val: nil},
        #     {id: 5, val: ""},
        #     {id: 5, val: nil},
        #     {id: 6, val: "p;"},
        #     {id: 6, val: ";z"},
        #     {id: 7, val: "m;;n"},
        #     {id: 7, val: "s"}
        #   ]
        #   expect(result).to eq(expected)
        class FieldValuesToNewRows
          include SepDeprecatable

          def initialize(target:, fields: [], multival: false, sep: nil,
                         delim: nil, keep_nil: false, keep_empty: false)
            @fields = [fields].flatten
            @target = target
            @multival = multival
            @sep = sep
            @delim = usedelim(sepval: sep, delimval: delim, calledby: self,
                              default: nil)
            @keep_nil = keep_nil
            @keep_empty = keep_empty
          end

          def process(row, &)
            rows = []
            other_fields = row.keys - @fields
            other_data = {}
            other_fields.each { |f| other_data[f] = row.fetch(f, nil) }

            @fields.each do |field|
              val = row.fetch(field, nil)
              vals = if val.nil?
                [nil]
              elsif val.empty?
                [""]
              elsif @multival
                val.split(@sep, -1)
              else
                [val]
              end

              vals.each do |val|
                next if !@keep_nil && val.nil?
                next if !(val.nil? || @keep_empty) && val.empty?

                new_row = other_data.clone
                new_row[@target] = val
                rows << new_row
              end
            end
            rows.each(&)
            nil
          end
        end
      end
    end
  end
end
