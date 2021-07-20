# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Prepend do
  describe 'FieldToFieldValue' do
    test_csv = 'tmp/test.csv'
    rows = [
      %w[name prependval],
      ['Weddy', 'm'], #0
      [nil, 'u'], 
      ['', 'u'], #2
      ['Kernel', nil],
      ['Divebomber|Hunter', 'm'], #4
      ['Divebomber|Niblet|Keet', 'm|f'],
      ['|Niblet', 'm|f'] #6
    ]

    context 'when called with multival prepend field and no mvdelim' do
      before do
        generate_csv(test_csv, rows)
      end

      it 'raises MissingDelimiterError' do
        msg = 'You must provide an mvdelim string if multivalue_prepended_field is true'
        opts = { target_field: :name, prepended_field: :prependval, sep: ':',
                multivalue_prepended_field: true }
        
        expect{execute_job(filename: test_csv,
                              xform: Prepend::FieldToFieldValue,
                              xformopt: opts)}.to raise_error(msg)
      end
    end
    
    context 'when delete_prepended = false' do
      before do
        generate_csv(test_csv, rows)
        @result = execute_job(filename: test_csv,
                              xform: Prepend::FieldToFieldValue,
                              xformopt: { target_field: :name, prepended_field: :prependval, sep: ': ',
                                         mvdelim: '|' })
      end
      it 'prepends value of given field to existing field values' do
        expected = { name: 'm: Weddy', prependval: 'm' }
        expect(@result[0]).to eq(expected)
      end
      it 'leaves nil values alone' do
        expected = { name: nil, prependval: 'u' }
        expect(@result[1]).to eq(expected)
      end
      it 'leaves blank values alone' do
        expected = { name: '', prependval: 'u' }
        expect(@result[2]).to eq(expected)
      end
      it 'does not prepend blank field' do
        expected = { name: 'Kernel', prependval: nil }
        expect(@result[3]).to eq(expected)
      end
      it 'prepends whole prepend field value to each value in target field' do
        expected = { name: 'm: Divebomber|m: Hunter', prependval: 'm' }
        expect(@result[4]).to eq(expected)
      end
      it 'prepends whole prepend field value to each value in target field' do
        expected = { name: 'm|f: Divebomber|m|f: Niblet|m|f: Keet', prependval: 'm|f' }
        expect(@result[5]).to eq(expected)
      end
      it 'prepends whole prepend field value to each populated value in target field' do
        expected = { name: '|m|f: Niblet', prependval: 'm|f' }
        expect(@result[6]).to eq(expected)
      end
    end
    context 'when delete_prepended = true' do
      before do
        generate_csv(test_csv, rows)
        @result = execute_job(filename: test_csv,
                              xform: Prepend::FieldToFieldValue,
                              xformopt: { target_field: :name, prepended_field: :prependval, sep: ': ',
                                         delete_prepended: true,
                                         mvdelim: '|' })
      end
      it 'deletes prepended field after prepending' do
        expected = { name: 'm: Weddy' }
        expect(@result[0]).to eq(expected)
      end
    end

    context 'when multivalue_prepended_field = false' do
      before do
        generate_csv(test_csv, rows)
        @result = execute_job(filename: test_csv,
                              xform: Prepend::FieldToFieldValue,
                              xformopt: { target_field: :name, prepended_field: :prependval, sep: ': ',
                                         delete_prepended: true,
                                         mvdelim: '|' })
      end
      context 'when one prepend value and two target values' do
        it 'adds prepend value to each target field' do
          expected = { name: 'm: Divebomber|m: Hunter' }
          expect(@result[4]).to eq(expected)
        end
      end

      context 'when two prepend values and three target values' do
        it 'adds full prepend value string to each target value' do
          expected = { name: 'm|f: Divebomber|m|f: Niblet|m|f: Keet' }
          expect(@result[5]).to eq(expected)
        end
      end

      context 'when two prepend values and two target values (blank and populated)' do
        it 'adds full prepend value string to populated target value' do
          expected = { name: '|m|f: Niblet' }
          expect(@result[6]).to eq(expected)
        end
      end
    end

    context 'when multivalue_prepended_field = true' do
      before do
        generate_csv(test_csv, rows)
        @result = execute_job(filename: test_csv,
                              xform: Prepend::FieldToFieldValue,
                              xformopt: { target_field: :name, prepended_field: :prependval, sep: ': ',
                                         delete_prepended: true,
                                         mvdelim: '|',
                                         multivalue_prepended_field: true })
      end
      context 'when one prepend value and two target values' do
        it 'adds prepend value to first target field value' do
          expected = { name: 'm: Divebomber|Hunter' }
          expect(@result[4]).to eq(expected)
        end
      end

      context 'when two prepend values and three target values' do
        it 'adds matching prepend value string to first two target values' do
          expected = { name: 'm: Divebomber|f: Niblet|Keet' }
          expect(@result[5]).to eq(expected)
        end
      end

      context 'when two prepend values and two target values (blank and populated)' do
        it 'adds matching prepend value string to populated target value' do
          expected = { name: '|f: Niblet' }
          expect(@result[6]).to eq(expected)
        end
      end
    end
  end

  describe 'ToFieldValue' do
    test_csv = 'tmp/test.csv'
    rows = [
      %w[id name],
      [1, 'Weddy'],
      [2, nil],
      [3, '']
    ]

    before do
      generate_csv(test_csv, rows)
      @result = execute_job(filename: test_csv,
                            xform: Prepend::ToFieldValue,
                            xformopt: { field: :name, value: 'name: ' })
    end
    it 'prepends given value to existing field values' do
      expected = { id: '1', name: 'name: Weddy' }
      expect(@result[0]).to eq(expected)
    end
    it 'leaves nil values alone' do
      expected = { id: '2', name: nil }
      expect(@result[1]).to eq(expected)
    end
    it 'leaves blank values alone' do
      expected = { id: '3', name: '' }
      expect(@result[2]).to eq(expected)
    end
  end
end
