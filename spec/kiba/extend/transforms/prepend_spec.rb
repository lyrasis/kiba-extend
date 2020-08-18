require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Prepend do
  describe 'ToFieldValue' do
    test_csv = 'tmp/test.csv'
    rows = [
      ['id', 'name'],
      [1, 'Weddy'],
      [2, nil],
      [3, '']
    ]

    before do
      generate_csv(test_csv, rows)
      @result = execute_job(filename: test_csv,
                           xform: Prepend::ToFieldValue,
                           xformopt: {field: :name, value: 'name: '})
    end
    it 'prepends given value to existing field values' do
      expected = {id: '1', name: 'name: Weddy'}
      expect(@result[0]).to eq(expected)
    end
    it 'leaves nil values alone' do
      expected = {id: '2', name: nil}
      expect(@result[1]).to eq(expected)
    end
    it 'leaves blank values alone' do
      expected = {id: '3', name: ''}
      expect(@result[2]).to eq(expected)
    end
  end
end
