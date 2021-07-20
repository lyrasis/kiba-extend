# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Append do
  let(:test_csv) { 'tmp/test.csv' }
  before { generate_csv(test_csv, rows) }

  describe 'NilFields' do
    let(:rows) do
      [
        %w[id z],
        [1, 'zz']
      ]
    end
    let(:result) do
      execute_job(filename: test_csv,
                  xform: Append::NilFields,
                  xformopt: { fields: %i[a b c z] })
    end
    it 'adds non-existing fields, populating with nil, while leaving existing fields alone' do
      expected = { id: '1', z: 'zz', a: nil, b: nil, c: nil }
      expect(result[0]).to eq(expected)
    end
  end

  describe 'ToFieldValue' do
    let(:rows) do
      [
        %w[id name],
        [1, 'Weddy'],
        [2, nil],
        [3, '']
      ]
    end
    let(:result) do
      execute_job(filename: test_csv,
                  xform: Append::ToFieldValue,
                  xformopt: { field: :name, value: ' (name)' })
    end
    it 'prepends given value to existing field values' do
      expected = { id: '1', name: 'Weddy (name)' }
      expect(result[0]).to eq(expected)
    end
    it 'leaves nil values alone' do
      expected = { id: '2', name: nil }
      expect(result[1]).to eq(expected)
    end
    it 'leaves blank values alone' do
      expected = { id: '3', name: '' }
      expect(result[2]).to eq(expected)
    end
  end
end
