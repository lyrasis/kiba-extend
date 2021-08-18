# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Utils::Lookup do
  rows = [
    %w[id val],
    %w[1 a],
    %w[2 b],
    %w[3 c],
    %w[3 d]
  ]
  before { generate_csv(rows) }
  after { File.delete(test_csv) if File.exist?(test_csv) }

  describe '#csv_to_hash' do
    lookup_hash = {
      '1' => { id: '1', val: 'a' },
      '2' => { id: '2', val: 'b' },
      '3' => { id: '3', val: 'd' }
    }

    it 'returns hash with key = keycolumn value and value = last occurring row w/that key ' do
      result = Lookup.csv_to_hash(file: test_csv,
                                  csvopt: CSVOPT,
                                  keycolumn: :id)
      expect(result).to eq(lookup_hash)
    end
  end

  describe '#csv_to_multi_hash' do
    lookup_hash = {
      '1' => [{ id: '1', val: 'a' }],
      '2' => [{ id: '2', val: 'b' }],
      '3' => [{ id: '3', val: 'c' },
              { id: '3', val: 'd' }]
    }

    it 'returns hash with key = keycolumn value and value = array of all rows w/that key ' do
      result = Lookup.csv_to_multi_hash(file: test_csv,
                                        csvopt: CSVOPT,
                                        keycolumn: :id)
      expect(result).to eq(lookup_hash)
    end
  end

  describe Lookup::CriteriaChecker do
    context 'when set match type not specified' do
      it 'defaults to set_type = :all' do
        set = { fieldsets: [
          {
            matches: [
              ['row::a', 'value:abc']
            ]
          }
        ] }
        obj = Lookup::CriteriaChecker.new(
          check_type: :equality,
          config: set,
          row: { a: 'def' }
        )
        expect(obj.type).to eq(:all)
      end
    end

    context 'when type = :all' do
      context 'and all fieldset groups return true' do
        it 'returns true' do
          set = { type: :all,
                  fieldsets: [
                    {
                      matches: [
                        ['row::a', 'value::abc']
                      ]
                    },
                    {
                      matches: [
                        ['row::b', 'value::def']
                      ]
                    }
                  ] }
          obj = Lookup::CriteriaChecker.new(
            check_type: :equality,
            config: set,
            row: { a: 'abc', b: 'def' }
          )
          expect(obj.result).to be true
        end
      end
    end
  end

  describe Lookup::SetChecker do
    context 'when set match type not specified' do
      it 'defaults to set_type = :any' do
        set = {
          matches: [
            ['row::a', 'value:abc'],
            ['row::a', 'value:def']
          ]
        }
        obj = Lookup::SetChecker.new(
          check_type: :equality,
          set: set,
          row: { a: 'def' }
        )
        expect(obj.set_type).to eq(:any)
      end
    end

    context 'when set match type = :any' do
      context 'and one or more of the matches = true' do
        it 'returns true' do
          set = {
            type: :any,
            matches: [
              ['row::a', 'value::abc'],
              ['row::a', 'value::def']
            ]
          }
          obj = Lookup::SetChecker.new(
            check_type: :equality,
            set: set,
            row: { a: 'def' }
          )
          expect(obj.result).to be true
        end
      end

      context 'and none of the matches = true' do
        it 'returns false' do
          set = {
            type: :any,
            matches: [
              ['row::a', 'value::abc'],
              ['row::a', 'value::def']
            ]
          }
          obj = Lookup::SetChecker.new(
            check_type: :equality,
            set: set,
            row: { a: 'ghi' }
          )
          expect(obj.result).to be false
        end
      end
    end

    context 'when set match type = :all' do
      context 'and one or more of the matches = true' do
        it 'returns true' do
          set = {
            type: :all,
            matches: [
              ['row::a', 'value::def'],
              ['row::b', 'mvmergerow::a']
            ]
          }
          obj = Lookup::SetChecker.new(
            check_type: :equality,
            set: set,
            row: { a: 'def', b: 'abc' },
            mergerow: { a: 'abc;xyz' },
            sep: ';'
          )
          expect(obj.result).to be true
        end
      end

      context 'and one or more matches = false' do
        it 'returns false' do
          set = {
            type: :all,
            matches: [
              ['row::a', 'value::abc'],
              ['row::b', 'mergerow::a']
            ]
          }
          obj = Lookup::SetChecker.new(
            check_type: :equality,
            set: set,
            row: { a: 'ghi', b: 'def' },
            mergerow: { a: 'abc' }
          )
          expect(obj.result).to be false
        end
      end
    end
  end

  describe Lookup::MultivalPairs do
    it 'explodes pairs into all multivalued comparisons' do
      obj = Lookup::MultivalPairs.new(
        pair: ['mvrow::a', 'mvrow::b'],
        row: { a: 'abc;def;xyz', b: 'def;nop' },
        sep: ';'
      )
      expected = [
        %w[value::abc value::def],
        %w[value::abc value::nop],
        %w[value::def value::def],
        %w[value::def value::nop],
        %w[value::xyz value::def],
        %w[value::xyz value::nop]
      ].sort
      expect(obj.result.sort).to eq(expected)
    end
  end

  describe Lookup::PairEquality do
    describe 'compares row values to basic string values' do
      context 'when row field value equals string value' do
        it 'returns true' do
          obj = Lookup::PairEquality.new(
            pair: ['row::a', 'value::abc'],
            row: { a: 'abc' }
          )
          expect(obj.result).to be true
        end
      end

      context 'when row field value not equal to string value' do
        it 'returns false' do
          obj = Lookup::PairEquality.new(
            pair: ['row::a', 'value::abc'],
            row: { a: 'a' }
          )
          expect(obj.result).to be false
        end
      end
    end

    describe 'compares row values to regexp values' do
      context 'when row field value equals regexp value' do
        it 'returns true' do
          obj = Lookup::PairEquality.new(
            pair: ['row::a', 'revalue::[Aa].c'],
            row: { a: 'abc' }
          )
          expect(obj.result).to be true
        end
      end

      context 'when row field value not equal to regexp value' do
        it 'returns false' do
          obj = Lookup::PairEquality.new(
            pair: ['row::a', 'revalue::[Aa].c'],
            row: { a: 'abcd' }
          )
          expect(obj.result).to be false
        end
      end

      context 'when regexp value explicitly includes ^ and/or $ anchors' do
        it 'does not re-add them' do
          obj = Lookup::PairEquality.new(
            pair: ['row::a', 'revalue::^[Aa].c$'],
            row: { a: 'abc' }
          )
          expect(obj.result).to be true
        end
      end
    end

    describe 'compares mergerow field values to basic string values' do
      context 'when mergerow field value equals string value' do
        it 'returns true' do
          obj = Lookup::PairEquality.new(
            pair: ['mergerow::a', 'value::abc'],
            row: { b: 'def' },
            mergerow: { a: 'abc' }
          )
          expect(obj.result).to be true
        end
      end

      context 'when mergerow field value not equal to string value' do
        it 'returns false' do
          obj = Lookup::PairEquality.new(
            pair: ['mergerow::a', 'value::abc'],
            row: { b: 'def' },
            mergerow: { a: 'ab' }
          )
          expect(obj.result).to be false
        end
      end

      context 'when mergerow is not passed to class' do
        it 'returns false' do
          obj = Lookup::PairEquality.new(
            pair: ['mergerow::a', 'value::abc'],
            row: { b: 'def' }
          )
          expect(obj.result).to be false
        end
      end
    end

    describe 'compares row field value to mergerow field value' do
      context 'when row and mergerow field values are equal' do
        it 'returns true' do
          obj = Lookup::PairEquality.new(
            pair: ['mergerow::a', 'row::b'],
            row: { b: 'abc' },
            mergerow: { a: 'abc' }
          )
          expect(obj.result).to be true
        end
      end

      context 'when row and mergerow field values are not equal' do
        it 'returns false' do
          obj = Lookup::PairEquality.new(
            pair: ['mergerow::a', 'row::b'],
            row: { b: 'abc' },
            mergerow: { a: 'def' }
          )
          expect(obj.result).to be false
        end
      end

      context 'when neither row nor mergerow contains its specified field' do
        it 'returns true' do
          obj = Lookup::PairEquality.new(
            pair: ['mergerow::a', 'row::b'],
            row: {},
            mergerow: {}
          )
          expect(obj.result).to be true
        end
      end

      context 'when row field exists but is blank and mergerow field does not exist' do
        it 'returns false' do
          obj = Lookup::PairEquality.new(
            pair: ['mergerow::a', 'row::b'],
            row: { b: '' },
            mergerow: {}
          )
          expect(obj.result).to be false
        end
      end
    end
  end

  describe Lookup::PairInclusion do
    describe 'checks if row value contains basic string values' do
      context 'when row field value contains string value' do
        it 'returns true' do
          obj = Lookup::PairInclusion.new(
            pair: ['row::a', 'value::bcd'],
            row: { a: 'abcdef' }
          )
          expect(obj.result).to be true
        end
      end

      context 'when row field value does not contain string value' do
        it 'returns false' do
          obj = Lookup::PairInclusion.new(
            pair: ['row::a', 'value::abc'],
            row: { a: 'a' }
          )
          expect(obj.result).to be false
        end
      end
    end

    describe 'checks if row values match regexp values' do
      context 'when row field value matches regexp value' do
        it 'returns true' do
          obj = Lookup::PairInclusion.new(
            pair: ['row::a', 'revalue::[Aa].c'],
            row: { a: 'zabcy' }
          )
          expect(obj.result).to be true
        end
      end

      context 'when row field value does not match regexp value' do
        it 'returns false' do
          obj = Lookup::PairInclusion.new(
            pair: ['row::a', 'revalue::[Aa].c'],
            row: { a: 'abCd' }
          )
          expect(obj.result).to be false
        end
      end

      context 'when regexp value explicitly includes ^ and/or $ anchors' do
        it 'treats them as expected in a regexp' do
          obj = Lookup::PairInclusion.new(
            pair: ['row::a', 'revalue::^[Aa].c$'],
            row: { a: 'abc' }
          )
          expect(obj.result).to be true
        end
      end

      context 'when row value is nil' do
        it 'returns false' do
          obj = Lookup::PairInclusion.new(
            pair: ['row::a', 'revalue::^[Aa].c$'],
            row: { a: nil }
          )
          expect(obj.result).to be false
        end
      end
    end

    describe 'compares mergerow field values to basic string values' do
      context 'when mergerow field value equals string value' do
        it 'returns true' do
          obj = Lookup::PairEquality.new(
            pair: ['mergerow::a', 'value::abc'],
            row: { b: 'def' },
            mergerow: { a: 'abc' }
          )
          expect(obj.result).to be true
        end
      end

      context 'when mergerow field value not equal to string value' do
        it 'returns false' do
          obj = Lookup::PairEquality.new(
            pair: ['mergerow::a', 'value::abc'],
            row: { b: 'def' },
            mergerow: { a: 'ab' }
          )
          expect(obj.result).to be false
        end
      end

      context 'when mergerow is not passed to class' do
        it 'returns false' do
          obj = Lookup::PairEquality.new(
            pair: ['mergerow::a', 'value::abc'],
            row: { b: 'def' }
          )
          expect(obj.result).to be false
        end
      end
    end

    describe 'compares row field value to mergerow field value' do
      context 'when row and mergerow field values are equal' do
        it 'returns true' do
          obj = Lookup::PairEquality.new(
            pair: ['mergerow::a', 'row::b'],
            row: { b: 'abc' },
            mergerow: { a: 'abc' }
          )
          expect(obj.result).to be true
        end
      end

      context 'when row and mergerow field values are not equal' do
        it 'returns false' do
          obj = Lookup::PairEquality.new(
            pair: ['mergerow::a', 'row::b'],
            row: { b: 'abc' },
            mergerow: { a: 'def' }
          )
          expect(obj.result).to be false
        end
      end

      context 'when neither row nor mergerow contains its specified field' do
        it 'returns true' do
          obj = Lookup::PairEquality.new(
            pair: ['mergerow::a', 'row::b'],
            row: {},
            mergerow: {}
          )
          expect(obj.result).to be true
        end
      end

      context 'when row field exists but is blank and mergerow field does not exist' do
        it 'returns false' do
          obj = Lookup::PairEquality.new(
            pair: ['mergerow::a', 'row::b'],
            row: { b: '' },
            mergerow: {}
          )
          expect(obj.result).to be false
        end
      end
    end
  end

  describe Lookup::RowSelector do
    context 'when inclusion criteria' do
      context 'includes :position => "first"' do
        it 'keeps only the first mergerow' do
          origrow = { source: 'adopted' }
          mergerows = [
            { treatment: 'hatch' },
            { treatment: 'adopted' },
            { treatment: 'hatch' },
            { treatment: 'adopted' },
            { treatment: 'deworm' }
          ]
          conditions = {
            include: {
              position: 'first'
            }
          }
          result = Lookup::RowSelector.new(origrow: origrow, mergerows: mergerows, conditions: conditions).result
          expected = [
            { treatment: 'hatch' }
          ]
          expect(result).to eq(expected)
        end
      end
      context 'includes :field_equal comparing to a string value' do
        it 'keeps only mergerows containing field equal to given value' do
          origrow = { source: 'adopted' }
          mergerows = [
            { treatment: 'hatch' },
            { treatment: 'adopted' },
            { treatment: 'hatch' },
            { treatment: 'adopted' },
            { treatment: 'deworm' }
          ]
          conditions = {
            include: {
              field_equal: { fieldsets: [
                {
                  type: :any,
                  matches: [
                    ['mergerow::treatment', 'value::hatch']
                  ]
                }
              ] }
            }
          }
          result = Lookup::RowSelector.new(origrow: origrow, mergerows: mergerows, conditions: conditions).result
          expected = [
            { treatment: 'hatch' },
            { treatment: 'hatch' }
          ]
          expect(result).to eq(expected)
        end
      end
      context 'includes :field_equal comparing to a regexp value' do
        it 'keeps only mergerows containing field matching given regexp' do
          origrow = { source: 'adopted' }
          mergerows = [
            { treatment: 'hatch' },
            { treatment: 'adopted' },
            { treatment: 'hatch' },
            { treatment: 'adopted' },
            { treatment: 'deworm' },
            { treatment: 'hatches' }
          ]
          conditions = {
            include: {
              field_equal: { fieldsets: [
                {
                  type: :any,
                  matches: [
                    ['mergerow::treatment', 'revalue::[Hh]atch']
                  ]
                }
              ] }
            }
          }
          result = Lookup::RowSelector.new(origrow: origrow, mergerows: mergerows, conditions: conditions).result
          expected = [
            { treatment: 'hatch' },
            { treatment: 'hatch' }
          ]
          expect(result).to eq(expected)
        end
      end
    end
    context 'when exclusion criteria' do
      context 'includes :src_field_equal_merge_field' do
        context 'with single pair of fields' do
          it 'rejects expected mergerows' do
            origrow = { source: 'adopted' }
            mergerows = [
              { treatment: 'hatch' },
              { treatment: 'adopted' },
              { treatment: 'hatch' },
              { treatment: 'adopted' },
              { treatment: 'deworm' }
            ]
            conditions = {
              exclude: {
                field_equal: { fieldsets: [
                  {
                    type: :any,
                    matches: [
                      ['row::source', 'mergerow::treatment']
                    ]
                  }
                ] }
              }
            }
            result = Lookup::RowSelector.new(origrow: origrow, mergerows: mergerows, conditions: conditions).result
            expected = [
              { treatment: 'hatch' },
              { treatment: 'hatch' },
              { treatment: 'deworm' }
            ]
            expect(result).to eq(expected)
          end
        end

        context 'with multiple pairs of fields' do
          it 'rejects expected mergerows' do
            origrow = { source: 'adopted', color: 'coral blue' }
            mergerows = [
              { treatment: 'hatch', gotfrom: 'adopted', type: 'pearl' },
              { treatment: 'hatch', gotfrom: 'adopted', type: 'coral blue' },
              { treatment: 'hatch', gotfrom: 'self', type: 'pearl' },
              { treatment: 'hatch', gotfrom: 'self', type: 'coral blue' },
              { treatment: 'adopted', gotfrom: 'friend', type: 'coral blue' },
              { treatment: 'adopted', gotfrom: 'friend', type: 'buff dundotte' },
              { treatment: 'purchased', gotfrom: 'friend', type: 'buff dundotte' },
              { treatment: 'purchased', gotfrom: 'adopted', type: 'royal purple' },
              { treatment: 'purchased', gotfrom: 'friend', type: 'coral blue' }
            ]
            conditions = {
              exclude: {
                field_equal: { fieldsets: [
                  {
                    type: :any,
                    matches: [
                      ['row::source', 'mergerow::treatment'],
                      ['row::source', 'mergerow::gotfrom'],
                      ['row::color', 'mergerow::type']
                    ]
                  }
                ] }
              }
            }
            result = Lookup::RowSelector.new(origrow: origrow, mergerows: mergerows, conditions: conditions).result
            expected = [
              { treatment: 'hatch', gotfrom: 'self', type: 'pearl' },
              { treatment: 'purchased', gotfrom: 'friend', type: 'buff dundotte' }
            ]
            expect(result).to eq(expected)
          end
        end
      end

      context 'includes :field_empty' do
        origrow = { source: 'adopted', color: 'coral blue' }
        mergerows = [
          { treatment: 'hatch', gotfrom: 'adopted', type: 'pearl' },
          { treatment: nil, gotfrom: '', type: 'coral blue' },
          { treatment: 'hatch', gotfrom: 'self', type: 'pearl' },
          { treatment: '', gotfrom: nil, type: 'coral blue' },
          { treatment: 'adopted', gotfrom: nil, type: 'coral blue' },
          { treatment: nil, gotfrom: nil, type: 'buff dundotte' },
          { treatment: 'purchased', gotfrom: 'friend', type: 'buff dundotte' },
          { treatment: '', gotfrom: '', type: 'royal purple' },
          { treatment: 'purchased', gotfrom: '', type: 'coral blue' }
        ]
        context 'when one field specified' do
          it 'rejects expected mergerows' do
            conditions = {
              exclude: {
                field_empty: {
                  fieldsets: [
                    { fields: %w[mergerow::treatment] }
                  ]
                }
              }
            }
            result = Lookup::RowSelector.new(origrow: origrow, mergerows: mergerows, conditions: conditions).result
            expected = [
              { treatment: 'hatch', gotfrom: 'adopted', type: 'pearl' },
              { treatment: 'hatch', gotfrom: 'self', type: 'pearl' },
              { treatment: 'adopted', gotfrom: nil, type: 'coral blue' },
              { treatment: 'purchased', gotfrom: 'friend', type: 'buff dundotte' },
              { treatment: 'purchased', gotfrom: '', type: 'coral blue' }
            ]
            expect(result).to eq(expected)
          end
        end
        context 'when multiple fields specified' do
          it 'rejects mergerows where ANY of the fields listed are empty' do
            conditions = {
              exclude: {
                field_empty: {
                  fieldsets: [
                    { type: :any, fields: %w[mergerow::treatment mergerow::gotfrom] }
                  ]
                }
              }
            }
            result = Lookup::RowSelector.new(origrow: origrow, mergerows: mergerows, conditions: conditions).result
            expected = [
              { treatment: 'hatch', gotfrom: 'adopted', type: 'pearl' },
              { treatment: 'hatch', gotfrom: 'self', type: 'pearl' },
              { treatment: 'purchased', gotfrom: 'friend', type: 'buff dundotte' }
            ]
            expect(result).to eq(expected)
          end
        end
      end
    end

    context 'when inclusion and exclusion criteria' do
      it 'rejects excluded before selecting included' do
        origrow = { source: 'adopted', color: 'coral blue' }
        mergerows = [
          { treatment: nil, gotfrom: '', type: 'coral blue' },
          { treatment: 'hatch', gotfrom: 'self', type: 'pearl' },
          { treatment: '', gotfrom: nil, type: 'coral blue' },
          { treatment: 'adopted', gotfrom: nil, type: 'coral blue' },
          { treatment: nil, gotfrom: nil, type: 'buff dundotte' },
          { treatment: 'purchased', gotfrom: 'friend', type: 'buff dundotte' },
          { treatment: '', gotfrom: '', type: 'royal purple' },
          { treatment: 'purchased', gotfrom: '', type: 'coral blue' },
          { treatment: 'hatch', gotfrom: 'adopted', type: 'pearl' }
        ]
        conditions = {
          exclude: {
            field_empty: {
              fieldsets: [
                { type: :all, fields: %w[mergerow::treatment mergerow::gotfrom] }
              ]
            }
          },
          include:
          {
            position: 'first'
          }
        }

        result = Lookup::RowSelector.new(origrow: origrow,
                                         mergerows: mergerows,
                                         conditions: conditions).result
        expected = [
          { treatment: 'hatch', gotfrom: 'self', type: 'pearl' }
        ]
        expect(result).to eq(expected)
      end
    end
  end
end
