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

  describe 'NormalizeForID' do
    test_csv = 'tmp/test.csv'
    rows = [
      ['id', 'subject'],
      [1, 'Oświęcim (Poland)'],
      [2, 'Oswiecim, Poland'],
      [3, 'Iași, Romania']
    ]

    before do
      generate_csv(test_csv, rows)
    end
    it 'normalizes as expected' do
      expected = [
        {id: '1', subject: 'Oświęcim (Poland)', norm: 'oswiecimpoland'},
        {id: '2', subject: 'Oswiecim, Poland',  norm: 'oswiecimpoland'},
        {id: '3', subject: 'Iași, Romania',     norm: 'iasiromania'}
       ]
      result = execute_job(filename: test_csv,
                           xform: Cspace::NormalizeForID,
                           xformopt: {source: :subject, target: :norm})
      expect(result).to eq(expected)
    end
  end
end

