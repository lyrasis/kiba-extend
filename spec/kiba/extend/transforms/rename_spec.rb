require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Rename do
  describe 'Field' do
    test_csv = 'tmp/test.csv'
    rows = [
      ['id', 'name', 'sex'],
      [1, 'Weddy', 'm'],
      [2, 'Kernel', 'f']
    ]

    before do
      generate_csv(test_csv, rows)
    end
    it 'renames field' do
      expected = [
        {:id=>'1', :name=>'Weddy', :gender=>'m'},
        {:id=>'2', :name=>'Kernel', :gender=>'f'}
      ]
      result = execute_job(filename: test_csv,
                           xform: Rename::Field,
                           xformopt: {from: :sex, to: :gender})
      expect(result).to eq(expected)
    end
  end
end
