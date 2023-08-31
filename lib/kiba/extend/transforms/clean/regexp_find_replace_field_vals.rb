# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Clean
        # Performs specified regular expression find/replace in the specified
        #   field(s)
        #
        # @example Basic match(default)
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
        # @example Handles start/end anchors
        #   xform = Clean::RegexpFindReplaceFieldVals.new(
        #     fields: :val,
        #     find: '^xx+',
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
        class RegexpFindReplaceFieldVals
          include Allable

          # @param fields [Array<Symbol>,Symbol,nil] in which to find/replace
          # @param find [String] make sure to use double quotes to match slash
          #   escaped characters (\n, etc)
          # @param replace [String]
          # @param casesensitive [Boolean]
          # @param multival [Boolean]
          # @param sep [String,nil] required if `multival: true`; if not given,
          #   will default to `Kiba::Extend.delim` value
          # @param debug [Boolean] if true, will put replacement value in a new
          #   field. New field name is same as old field name, with "_repl"
          #   suffix added
          def initialize(fields:, find:, replace:, casesensitive: true,
            multival: false, sep: nil, debug: false)
            @fields = [fields].flatten
            @find = if casesensitive == true
              Regexp.new(find)
            else
              Regexp.new(find, Regexp::IGNORECASE)
            end
            @replace = replace
            @debug = debug
            @mv = multival
            @sep = set_sep(sep)
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            finalize_fields(row)

            fields.each do |field|
              oldval = row.fetch(field, nil)
              next if oldval.nil?
              next unless oldval.is_a?(String)

              newval = mv ? mv_find_replace(oldval) : sv_find_replace(oldval)
              target = debug ? "#{field}_repl".to_sym : field
              row[target] = newval.blank? ? nil : newval
            end
            row
          end

          private

          attr_reader :fields, :find, :replace, :debug, :mv, :sep

          def mv_find_replace(val)
            val.split(sep).map { |v| v.gsub(find, replace) }.join(sep)
          end

          def set_sep(sep)
            return sep unless mv
            return Kiba::Extend.delim if mv && !sep

            sep
          end

          def sv_find_replace(val)
            val.gsub(find, replace)
          end
        end
      end
    end
  end
end
