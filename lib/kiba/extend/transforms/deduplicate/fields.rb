# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Deduplicate
        # Removes the value(s) of `source` from `targets`
        #
        # @example Multival, case sensitive, without sep param
        #   # Used in pipeline as:
        #   # transform Deduplicate::Fields,
        #   #   source: :x,
        #   #   targets: %i[y z],
        #   #   multival: true,
        #   Kiba::Extend.config.delim = ';'
        #   xform = Deduplicate::Fields.new(
        #     source: :x,
        #     targets: %i[y z],
        #     multival: true
        #   )
        #   input = [
        #     {x: "a", y: "a", z: "b"},
        #     {x: "a", y: "a", z: "a"},
        #     {x: "a", y: "b;a", z: "a;c"},
        #     {x: "a;b", y: "b;a", z: "a;c"},
        #     {x: "a", y: "aa", z: "bat"},
        #     {x: nil, y: "a", z: nil},
        #     {x: "", y: ";a", z: "b;"},
        #     {x: "a", y: nil, z: nil},
        #     {x: "a", y: "A", z: "a"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   Kiba::Extend.reset_config
        #   expected = [
        #     {x: "a", y: nil, z: "b"},
        #     {x: "a", y: nil, z: nil},
        #     {x: "a", y: "b", z: "c"},
        #     {x: "a;b", y: nil, z: "c"},
        #     {x: "a", y: "aa", z: "bat"},
        #     {x: nil, y: "a", z: nil},
        #     {x: "", y: "a", z: "b"},
        #     {x: "a", y: nil, z: nil},
        #     {x: "a", y: "A", z: nil}
        #   ]
        #   expect(result).to eq(expected)
        # @example No multival param, case sensitive, with delim
        #   # Used in pipeline as:
        #   # transform Deduplicate::Fields,
        #   #   source: :x,
        #   #   targets: %i[y z],
        #   #   delim: ";"
        #   xform = Deduplicate::Fields.new(
        #     source: :x,
        #     targets: %i[y z],
        #     delim: ";"
        #   )
        #   input = [
        #     {x: "a", y: "a", z: "b"},
        #     {x: "a", y: "a", z: "a"},
        #     {x: "a", y: "b;a", z: "a;c"},
        #     {x: "a;b", y: "b;a", z: "a;c"},
        #     {x: "a", y: "aa", z: "bat"},
        #     {x: nil, y: "a", z: nil},
        #     {x: "", y: ";a", z: "b;"},
        #     {x: "a", y: nil, z: nil},
        #     {x: "a", y: "A", z: "a"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {x: "a", y: nil, z: "b"},
        #     {x: "a", y: nil, z: nil},
        #     {x: "a", y: "b", z: "c"},
        #     {x: "a;b", y: nil, z: "c"},
        #     {x: "a", y: "aa", z: "bat"},
        #     {x: nil, y: "a", z: nil},
        #     {x: "", y: "a", z: "b"},
        #     {x: "a", y: nil, z: nil},
        #     {x: "a", y: "A", z: nil}
        #   ]
        #   expect(result).to eq(expected)
        # @example Multival, case insensitive, with sep
        #   # Used in pipeline as:
        #   # transform Deduplicate::Fields,
        #   #   source: :x,
        #   #   targets: %i[y z],
        #   #   multival: true,
        #   #   sep: ";",
        #   #   casesensitive: false
        #   xform = Deduplicate::Fields.new(
        #     source: :x,
        #     targets: %i[y z],
        #     multival: true,
        #     sep: ";",
        #     casesensitive: false
        #   )
        #   input = [
        #     {x: "a", y: "A;a", z: "a"},
        #     {x: "a", y: "a", z: "B;A"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {x: "a", y: nil, z: nil},
        #     {x: "a", y: nil, z: "B"}
        #   ]
        #   expect(result).to eq(expected)
        # @example Single val, case insensitive
        #   # Used in pipeline as:
        #   # transform Deduplicate::Fields,
        #   #   source: :x,
        #   #   targets: %i[y z],
        #   #   casesensitive: false
        #   xform = Deduplicate::Fields.new(
        #     source: :x,
        #     targets: %i[y z],
        #     casesensitive: false
        #   )
        #   input = [
        #     {x: "a", y: "A", z: "a"},
        #     {x: "a", y: "a", z: "B"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {x: "a", y: nil, z: nil},
        #     {x: "a", y: nil, z: "B"}
        #   ]
        #   expect(result).to eq(expected)
        class Fields
          include MultivalPlusDelimDeprecatable
          include SepDeprecatable

          # @param source [Symbol] name of field containing value to remove from
          #   target fields
          # @param targets [Array<Symbol>] names of fields to remove source
          #   value(s) from
          # @param casesensitive [Boolean] whether matching should be case
          #   sensitive
          # @param multival [Boolean] **DEPRECATED** - Do not use
          # @param sep [String] **DEPRECATED** - Do not use
          # @param delim [nil, String] non-nil is used to split values in source
          #   and targets values
          def initialize(source:, targets:, casesensitive: true,
            multival: omitted = true, sep: nil, delim: nil)
            @source = source
            @casesensitive = casesensitive
            @multival = if omitted && delim
              true
            else
              set_multival(multival, omitted, self)
            end
            if sep.nil? && delim.nil? && multival && !omitted
              msg = "If you are expecting Kiba::Extend.delim to be used as "\
                "default `sep` value, please pass it as explicit `delim` "\
                "argument. In a future release of kiba-extend, the `delim` "\
                "value will no longer default to Kiba::Extend.delim."
              warn("#{Kiba::Extend.warning_label}:\n  #{self.class}: #{msg}")
              sep = Kiba::Extend.delim
            end
            @delim = usedelim(sepval: sep, delimval: delim, calledby: self,
              default: nil)
            getter_params = if @delim
              {fields: targets, delim: @delim}
            else
              {fields: targets}
            end
            @getter = Helpers::FieldValueGetter.new(**getter_params)
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            sourceval = row[source]
            return row unless sourceval

            targetdata = getter.call(row)
            return row if targetdata.empty?

            sourcevals = split_value(sourceval)
            targetdata.transform_values! { |val| split_value(val) }

            deduplicate(row, sourcevals, targetdata)
            row
          end

          private

          attr_reader :source, :casesensitive, :multival, :delim, :getter

          def split_value(val)
            return [val.strip] unless multival
            return [""] if val.empty?

            val.split(delim, -1).map(&:strip)
          end

          def deduplicate(row, sourcevals, targetdata)
            identify_deletes(sourcevals, targetdata)
              .reject { |k, v| v.empty? }
              .each do |field, deletes|
                do_deletes(row, targetdata, field, deletes)
              end
          end

          def identify_deletes(sourcevals, targetdata)
            targetdata.transform_values do |val|
              id_target_deletes(sourcevals, val)
            end
          end

          def id_target_deletes(sourcevals, vals)
            return vals.intersection(sourcevals) if casesensitive

            lower_srcs = sourcevals.map(&:downcase)
            vals.select { |val| lower_srcs.include?(val.downcase) }
          end

          def do_deletes(row, targetdata, field, deletes)
            remain = targetdata[field] - deletes
            row[field] = if remain.empty?
              nil
            else
              remain.join(delim)
            end
          end
        end
      end
    end
  end
end
