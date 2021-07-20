require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Cspace do
  describe 'ConvertToID' do
    test_csv = 'tmp/test.csv'
    rows = [
      %w[id name],
      [1, 'Weddy1']
    ]

    before do
      generate_csv(test_csv, rows)
    end
    it 'inserts CS shortID of given source into target' do
      expected = [
        { id: '1', name: 'Weddy1', sid: 'Weddy13761760099' }
      ]
      result = execute_job(filename: test_csv,
                           xform: Cspace::ConvertToID,
                           xformopt: { source: :name, target: :sid })
      expect(result).to eq(expected)
    end
  end

  describe 'FlagInvalidCharacters' do
    test_csv = 'tmp/test.csv'
    rows = [
      ['subject'],
      ['Iași, Romania'],
      ['Iasi, Romania']
    ]

    before do
      generate_csv(test_csv, rows)
      @old = Cspace.const_get('BRUTEFORCE')
      Cspace.const_set('BRUTEFORCE', {})
    end
    after do
      Cspace.const_set('BRUTEFORCE', @old)
    end
    it 'adds column containing field value with invalid chars replaced with ?' do
      expected = [
        { subject: 'Iași, Romania', flag: 'Ia%INVCHAR%i, Romania' },
        { subject: 'Iasi, Romania', flag: nil }
      ]
      result = execute_job(filename: test_csv,
                           xform: Cspace::FlagInvalidCharacters,
                           xformopt: { check: :subject, flag: :flag })
      expect(result).to eq(expected)
    end
  end

  describe 'NormalizeForID' do
    test_csv = 'tmp/test.csv'
    rows = [
      %w[id subject],
      [1, 'Oświęcim (Poland)'],
      [2, 'Oswiecim, Poland'],
      [3, 'Iași, Romania'],
      [4, 'Iasi, Romania']
    ]

    before do
      generate_csv(test_csv, rows)
    end
    it 'normalizes as expected' do
      expected = [
        { id: '1', subject: 'Oświęcim (Poland)', norm: 'oswiecimpoland' },
        { id: '2', subject: 'Oswiecim, Poland', norm: 'oswiecimpoland' },
        { id: '3', subject: 'Iași, Romania', norm: 'iasiromania' },
        { id: '4', subject: 'Iasi, Romania', norm: 'iasiromania' }
      ]
      result = execute_job(filename: test_csv,
                           xform: Cspace::NormalizeForID,
                           xformopt: { source: :subject, target: :norm })
      expect(result).to eq(expected)
    end
  end
end
