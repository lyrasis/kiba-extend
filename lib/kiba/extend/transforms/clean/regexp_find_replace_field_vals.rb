# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Clean
        # Performs specified regular expression find/replace in the specified
        #   field(s)
        #
        # @example Basic match(default with find passed as String)
        #   # Used in pipeline as:
        #   # transform Clean::RegexpFindReplaceFieldVals,
        #   #   fields: :val,
        #   #   find: 'xx+',
        #   #   replace: 'exes'
        #   xform = Clean::RegexpFindReplaceFieldVals.new(
        #     fields: :val,
        #     find: 'xx+',
        #     replace: 'exes'
        #   )
        #   input = [
        #     {val: 'xxxxxx a thing'},
        #     {val: 'thing xxxx 123'},
        #     {val: 'x files'}
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {val: 'exes a thing'},
        #     {val: 'thing exes 123'},
        #     {val: 'x files'}
        #   ]
        #   expect(result).to eq(expected)
        # @example Handles start/end anchors, find passed as Regexp
        #   xform = Clean::RegexpFindReplaceFieldVals.new(
        #     fields: :val,
        #     find: /^xx+/,
        #     replace: 'exes'
        #   )
        #   input = [
        #     {val: 'xxxxxx a thing'},
        #     {val: 'thing xxxx 123'}
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {val: 'exes a thing'},
        #     {val: 'thing xxxx 123'}
        #   ]
        #   expect(result).to eq(expected)
        # @example Case insensitive
        #   xform = Clean::RegexpFindReplaceFieldVals.new(
        #     fields: :val,
        #     find: 'thing',
        #     replace: 'object',
        #     casesensitive: false
        #   )
        #   input = [
        #     {val: 'the thing'},
        #     {val: 'The Thing'}
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {val: 'the object'},
        #     {val: 'The object'}
        #   ]
        #   expect(result).to eq(expected)
        # @example Case insensitive regexp
        #   xform = Clean::RegexpFindReplaceFieldVals.new(
        #     fields: :val,
        #     find: /thing/i,
        #     replace: 'object'
        #   )
        #   input = [
        #     {val: 'the thing'},
        #     {val: 'The Thing'}
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {val: 'the object'},
        #     {val: 'The object'}
        #   ]
        #   expect(result).to eq(expected)
        # @example Matching/replacing line breaks (note double quotes)
        #   xform = Clean::RegexpFindReplaceFieldVals.new(
        #     fields: :val,
        #     find: "\n",
        #     replace: ''
        #   )
        #   s1 = <<~STR
        #
        #          pace/mcgill
        #        STR
        #   s2 = <<~STR
        #          pace/mcgill
        #
        #        STR
        #   input = [
        #     {val: s1},
        #     {val: s2},
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {val: 'pace/mcgill'},
        #     {val: 'pace/mcgill'}
        #   ]
        #   expect(result).to eq(expected)
        # @example With capture groups
        #   xform = Clean::RegexpFindReplaceFieldVals.new(
        #     fields: :val,
        #     find: '^(a) (thing)',
        #     replace: 'about \1 curious \2'
        #   )
        #   input = [
        #     {val: 'a thing'}
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {val: 'about a curious thing'},
        #   ]
        #   expect(result).to eq(expected)
        # @example When result is empty string
        #   xform = Clean::RegexpFindReplaceFieldVals.new(
        #     fields: :val,
        #     find: 'xx+',
        #     replace: ''
        #   )
        #   input = [
        #     {val: nil},
        #     {val: []},
        #     {val: ''},
        #     {val: 'xxxxx'}
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {val: nil},
        #     {val: []},
        #     {val: nil},
        #     {val: nil}
        #   ]
        #   expect(result).to eq(expected)
        # @example With multiple fields
        #   xform = Clean::RegexpFindReplaceFieldVals.new(
        #     fields: %i[val another],
        #     find: 'xx+',
        #     replace: ''
        #   )
        #   input = [
        #     {val: 'xxxx1', another: 'xxxx2xxxx'}
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {val: '1', another: '2'}
        #   ]
        #   expect(result).to eq(expected)
        # @example With `fields: :all`
        #   xform = Clean::RegexpFindReplaceFieldVals.new(
        #     fields: :all,
        #     find: 'xx+',
        #     replace: ''
        #   )
        #   input = [
        #     {val: 'xxxx1', another: 'xxxx2xxxx'}
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {val: '1', another: '2'}
        #   ]
        #   expect(result).to eq(expected)
        # @example With `debug: true`
        #   xform = Clean::RegexpFindReplaceFieldVals.new(
        #     fields: :val,
        #     find: 's$',
        #     replace: '',
        #     debug: true
        #   )
        #   input = [
        #     {val: 'bats|bats'}
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {val: 'bats|bats', val_repl: 'bats|bat'}
        #   ]
        #   expect(result).to eq(expected)
        #
        # @example With `multival: true` and :sep
        #   xform = Clean::RegexpFindReplaceFieldVals.new(
        #     fields: :val,
        #     find: 's$',
        #     replace: '',
        #     multival: true,
        #     sep: ';'
        #   )
        #   input = [
        #     {val: 'bats;bats'}
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {val: 'bat;bat'}
        #   ]
        #   expect(result).to eq(expected)
        # @example With `multival: true` and no :sep
        #   Kiba::Extend.config.delim = '|'
        #   xform = Clean::RegexpFindReplaceFieldVals.new(
        #     fields: :val,
        #     find: 's$',
        #     replace: '',
        #     multival: true
        #   )
        #   input = [
        #     {val: 'bats|bats'}
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   Kiba::Extend.reset_config
        #   expected = [
        #     {val: 'bat|bat'}
        #   ]
        #   expect(result).to eq(expected)
        # @example With no `multival` param and delim
        #   xform = Clean::RegexpFindReplaceFieldVals.new(
        #     fields: :val,
        #     find: 's$',
        #     replace: '',
        #     delim: "|"
        #   )
        #   input = [
        #     {val: 'bats|bats'}
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {val: 'bat|bat'}
        #   ]
        #   expect(result).to eq(expected)
        class RegexpFindReplaceFieldVals
          include Allable
          include MultivalPlusDelimDeprecatable
          include SepDeprecatable

          # @param fields [Array<Symbol>,Symbol,nil] in which to find/replace
          # @param find [String, Regexp] If passing a string, make
          #   sure to use double quotes to match slash escaped
          #   characters (\n, etc)
          # @param replace [String]
          # @param casesensitive [Boolean]
          # @param multival [Boolean] **DEPRECATED** - Do not use
          # @param sep [String,nil] **DEPRECATED** - Do not use
          # @param delim [nil, String] used to split the field value before
          #   performing find/replace if non-nil
          # @param debug [Boolean] if true, will put replacement value in a new
          #   field. New field name is same as old field name, with "_repl"
          #   suffix added
          def initialize(fields:, find:, replace:, casesensitive: true,
            multival: omitted = true, sep: nil, delim: nil,
            debug: false)
            @fields = [fields].flatten
            @find = build_pattern(find, casesensitive)
            @replace = replace
            @debug = debug
            @mv = if omitted && delim
              true
            else
              set_multival(multival, omitted, self)
            end

            if sep.nil? && delim.nil? && mv && !omitted
              msg = "If you are expecting Kiba::Extend.delim to be used as "\
                "default `sep` value, please pass it as explicit `delim` "\
                "argument. In a future release of kiba-extend, the `delim` "\
                "value will no longer default to Kiba::Extend.delim."
              warn("#{Kiba::Extend.warning_label}:\n  #{self.class}: #{msg}")
              sep = Kiba::Extend.delim
            end
            @delim = usedelim(sepval: sep, delimval: delim, calledby: self,
              default: nil)
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            finalize_fields(row)

            fields.each do |field|
              oldval = row.fetch(field, nil)
              next if oldval.nil?
              next unless oldval.is_a?(String)

              newval = mv ? mv_find_replace(oldval) : sv_find_replace(oldval)
              target = debug ? :"#{field}_repl" : field
              row[target] = newval.blank? ? nil : newval
            end
            row
          end

          private

          attr_reader :fields, :find, :replace, :debug, :mv, :sep, :delim

          def build_pattern(find, casesensitive)
            case find
            when Regexp
              find
            when String
              if casesensitive == true
                Regexp.new(find)
              else
                Regexp.new(find, Regexp::IGNORECASE)
              end
            end
          end

          def mv_find_replace(val)
            val.split(delim).map { |v| v.gsub(find, replace) }.join(delim)
          end

          def sv_find_replace(val)
            val.gsub(find, replace)
          end
        end
      end
    end
  end
end
