# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Replace
        # Looks up value of `source` field in given `mapping` Hash. Replaces orignal value with the result.
        #
        # Optional: put result in new `target` field; look up multiple values from a multivalue source field,
        #   provide a fallback value if source value is not found in mapping
        #
        # ## Examples
        #
        # The examples all share the following `mapping` Hash:
        #
        # ```
        # {
        #   'cb' => 'coral blue',
        #   'rp' => 'royal purple',
        #   'p' => 'pied',
        #   'pl' => 'pearl gray',
        #   nil => 'undetermined'
        # }
        # ```
        #
        # Initial examples all use the following rows as input:
        #
        # ```
        # [
        #   {name: 'Lazarus', color: 'cb'},
        #   {name: 'Inkpot', color: 'rp'},
        #   {name: 'Zipper', color: 'rp|p'},
        #   {name: 'Divebomber|Earlybird', color: 'pl|pl'},
        #   {name: 'Vern', color: 'v'},
        #   {name: 'Clover|Hops', color: 'rp|c'},
        #   {name: 'New', color: nil},
        #   {name: 'Old', color: ''},
        #   {name: 'New|Hunter', color: '|pl'}
        # ]
        # ```
        #
        # Using:
        #
        # ```
        # transform Replace::FieldValueWithStaticMapping, source: :color, mapping: mapping
        # ```
        #
        # Results in:
        #
        # ```
        # [
        #   {name: 'Lazarus', color: 'coral blue'},
        #     {name: 'Inkpot', color: 'royal purple'},
        #     {name: 'Zipper', color: 'rp|p'},
        #     {name: 'Divebomber|Earlybird', color: 'pl|pl'},
        #     {name: 'Vern', color: 'v'},
        #     {name: 'Clover|Hops', color: 'rp|c'},
        #     {name: 'New', color: 'undetermined'},
        #     {name: 'Old', color: ''},
        #     {name: 'New|Hunter', color: '|pl'}
        # ]
        # ```
        #
        # Using:
        #
        # ```
        # transform Replace::FieldValueWithStaticMapping, source: :color, target: :fullcol, mapping: mapping
        # ```
        #
        # Results in (showing first row only):
        #
        # ```
        # [
        #   {name: 'Lazarus', fullcol: 'coral blue'},
        #   ...
        # ]
        # ```
        #
        # Using:
        #
        # ```
        # transform Replace::FieldValueWithStaticMapping,
        #   source: :color,
        #   target: :fullcol,
        #   mapping: mapping,
        #   delete_source: false
        # ```
        #
        # Results in (showing first row only):
        #
        # ```
        # [
        #   {name: 'Lazarus', color: 'cb', fullcol: 'coral blue'},
        #   ...
        # ]
        # ```
        #
        # Using:
        #
        # ```
        # transform Replace::FieldValueWithStaticMapping,
        #   source: :color,
        #   mapping: mapping,
        #   delim: '|'
        # ```
        #
        # Results in:
        #
        # ```
        # [
        #   {name: 'Lazarus', color: 'coral blue'},
        #   {name: 'Inkpot', color: 'royal purple'},
        #   {name: 'Zipper', color: 'royal purple|pied'},
        #   {name: 'Divebomber|Earlybird', color: 'pearl gray|pearl gray'},
        #   {name: 'Vern', color: 'v'},
        #   {name: 'Clover|Hops', color: 'royal purple|c'},
        #   {name: 'New', color: 'undetermined'},
        #   {name: 'Old', color: ''},
        #   {name: 'New|Hunter', color: '|pearl gray'}
        # ]
        # ```
        #
        # The remaining examples use only the following rows as input:
        #
        # ```
        # [
        #   {name: 'Vern', color: 'v'},
        #   {name: 'Clover|Hops', color: 'rp|c'},
        #   {name: 'New', color: nil},
        #   {name: 'Old', color: ''},
        #   {name: 'New|Hunter', color: '|pl'}
        # ]
        # ```
        #
        # Using:
        #
        # ```
        # transform Replace::FieldValueWithStaticMapping,
        #   source: :color,
        #   mapping: mapping,
        #   delim: '|',
        #   fallback_val: :nil
        # ```
        #
        # Results in:
        #
        # ```
        # [
        #   {name: 'Vern', color: nil},
        #   {name: 'Clover|Hops', color: 'royal purple|'},
        #   {name: 'New', color: 'undetermined'},
        #   {name: 'Old', color: nil},
        #   {name: 'New|Hunter', color: '|pearl gray'}
        # ]
        # ```
        #
        # Using:
        #
        # ```
        # transform Replace::FieldValueWithStaticMapping,
        #   source: :color,
        #   mapping: mapping,
        #   delim: '|',
        #   fallback_val: 'nope'
        # ```
        #
        # Results in:
        #
        # ```
        # [
        #   {name: 'Vern', color: 'nope'},
        #   {name: 'Clover|Hops', color: 'royal purple|nope'},
        #   {name: 'New', color: 'undetermined'},
        #   {name: 'Old', color: 'nope'},
        #   {name: 'New|Hunter', color: 'nope|pearl gray'}
        # ]
        # ```
        class FieldValueWithStaticMapping
          class << self
            def multival_msg
              <<~MSG
              #{self.name} no longer supports the `multival` parameter.
              If a `delim` value is given, the transform will operate in multival mode
              TO FIX: remove `multival` parameter, ensuring a `delim` value is given
              MSG
            end

            # Overridden to provide more informative/detailed ArgumentError messages for parameters that are
            #   removed after not having been deprecated very long.
            def new(source:, target: nil, mapping:, fallback_val: :orig, delete_source: true, delim: nil,
                    multival: nil, sep: nil)
              instance = allocate
              fail(ArgumentError, sep_msg) if sep
              fail(ArgumentError, multival_msg) if multival
              instance.send(:initialize, **{source: source, target: target, mapping: mapping, fallback_val: fallback_val,
                                            delete_source: delete_source, delim: delim})
              instance
            end

            def sep_msg
              <<~MSG
              #{self.name} no longer supports the `sep` parameter
              TO FIX: change `sep` to `delim`"
              MSG
            end
          end

          # @param source [Symbol] the field containing the value to look up for mapping
          # @param target [nil, Symbol] optional new field in which to put the mapped/looked up result
          # @param mapping [Hash] keys = source field values
          # @param fallback_val [:orig, :nil, String] value to use if no match for source value is found
          #   in mapping
          # @param delete_source [Boolean] whether to remove source field after mapping. Has no effect if
          #   a different target field is not given
          # @param delim [nil, String] if a value is given, turns on "multival" mode, splitting the whole field
          #   value on the string given (since 3.0.0)
          def initialize(source:, target: nil, mapping:, fallback_val: :orig, delete_source: true, delim: nil)
            @source = source
            @target = target ? target : source
            @mapping = mapping
            @fallback = fallback_val
            @del = delete_source
            @delim = delim
            @multival = true if @delim
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            set_initial_value(row)
            rowval = row[source]
            vals = prep_vals(rowval)

            @fallback_val = get_fallback_vals(vals)

            row[target] = join_result(result(vals))

            row.delete(source) if source != target && del
            row
          end

          private

          attr_reader :source, :target, :mapping, :fallback, :del, :multival, :sep, :delim,
            :fallback_val

          def get_fallback_val(source_val)
            case fallback
            when :orig
              source_val
            when :nil
              nil
            else
              fallback
            end
          end

          def get_fallback_vals(source_vals)
            source_vals.map{ |val| get_fallback_val(val) }
          end

          def join_result(results)
            return nil if results.length == 1 && results.first.nil?

            multival ? results.join(delim) : results.first
          end

          def result(vals)
            vals.map.with_index{ |v, i| mapping.fetch(v, fallback_val[i]) }
          end

          def prep_vals(val)
            return [nil] if val.nil?
            return [''] if val.empty?

            multival ? val.split(delim, -1) : [val]
          end

          def set_delim(sep, delim)
            if delim && sep
              warn(self.class.delim_and_sep_warning)
              delim
            elsif sep
              warn(self.class.sep_warning)
              sep
            else
              delim
            end
          end

          def set_initial_value(row)
            return if source == target

            row[target] = nil
          end
        end
      end
    end
  end
end
