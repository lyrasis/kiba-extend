require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Cspace do
  describe 'ConvertToID' do
    test_csv = 'tmp/test.csv'
    rows = [
      ['id', 'name'],
      [1, 'Weddy1']
    ]

    before do
      generate_csv(test_csv, rows)
    end
    it 'inserts CS shortID of given source into target' do
      expected = [
        {:id=>'1', :name=>'Weddy1', :sid=>'Weddy13761760099'}
       ]
      result = execute_job(filename: test_csv,
                           xform: Cspace::ConvertToID,
                           xformopt: {source: :name, target: :sid})
      expect(result).to eq(expected)
    end
  end
end

