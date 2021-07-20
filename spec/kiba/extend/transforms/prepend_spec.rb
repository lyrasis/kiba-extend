# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Prepend do
  describe 'FieldToFieldValue' do
    test_csv = 'tmp/test.csv'
    rows = [
      %w[name prependval],
      %w[Weddy m],
      [nil, 'u'],
      ['', 'u'],
      ['Kernel', nil],
      ['Divebomber|Hunter', 'm'],
      ['Divebomber|Niblet|Keet', 'm|f'],
      ['Divebomber|Hunter', 'm']
    ]

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
      it 'prepends to each multivalue in target field' do
        expected = { name: 'm: Divebomber|m: Hunter', prependval: 'm' }
        expect(@result[4]).to eq(expected)
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
      it 'prepends value of given field to existing field values' do
        expected = { name: 'm: Weddy' }
        expect(@result[0]).to eq(expected)
      end
      it 'leaves nil values alone' do
        expected = { name: nil }
        expect(@result[1]).to eq(expected)
      end
      it 'leaves blank values alone' do
        expected = { name: '' }
        expect(@result[2]).to eq(expected)
      end
      it 'does not prepend blank field' do
        expected = { name: 'Kernel' }
        expect(@result[3]).to eq(expected)
      end
      it 'prepends to each multivalue in target field' do
        expected = { name: 'm: Divebomber|m: Hunter' }
        expect(@result[4]).to eq(expected)
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
      it 'prepends multivalue value to each multivalue in target field' do
        expected = { name: 'm|f: Divebomber|m|f: Niblet|m|f: Keet' }
        expect(@result[5]).to eq(expected)
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
      it 'prepends multivalue value to each multivalue in target field' do
        expected = { name: 'm: Divebomber|f: Niblet|f: Keet' }
        expect(@result[5]).to eq(expected)
      end
      it 'prepends multivalue value to each multivalue in target field' do
        expected = { name: 'm: Divebomber|m: Hunter' }
        expect(@result[6]).to eq(expected)
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
