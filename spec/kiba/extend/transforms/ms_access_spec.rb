require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::MsAccess do
  describe 'ScientificNotationToNumberString' do
    test_csv = 'tmp/test.csv'
    rows = [
      ['id', 'width'],
      [1, '1.70000000e+01'],
      [2, '170'],
      [3, ''],
      [4, nil],
      [5, '1.0e-10']
    ]

    before do
      generate_csv(test_csv, rows)
    end
    it 'converts scientific notation value to number string' do
      expected = [
        {id: '1', width: '17'},
        {id: '2', width: '170'},
        {id: '3', width: ''},
        {id: '4', width: nil},
        {id: '5', width: '0.0000000001'}
       ]
      result = execute_job(filename: test_csv,
                           xform: MsAccess::ScientificNotationToNumberString,
                           xformopt: {fields: %i[width]})
      expect(result).to eq(expected)
    end
  end
end

