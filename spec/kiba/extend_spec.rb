# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend do
  it 'has a version number' do
    expect(Kiba::Extend::VERSION).not_to be nil
  end

  describe ':stripplus csv converter' do
    rows = [
      %w[id val],
      ['1', ' a b'],
      ['2', ' a b '],
      ['3', ' a    b,  ']
    ]

    before { generate_csv(test_csv, rows) }
    it 'converts input data' do
      result = job_csv(filename: test_csv, incsvopt: { converters: [:stripplus] })
      compile = result.map { |e| e[:val] }.uniq
      expect(compile[0]).to eq('a b')
    end
    after { File.delete(test_csv) if File.exist?(test_csv) }
  end

  describe ':nulltonil csv converter' do
    rows = [
      %w[id val],
      %w[1 NULL],
      ['2', 'a NULL value'],
      ['3', ' NULL']
    ]

    before { generate_csv(test_csv, rows) }
    it 'converts input data' do
      expected = [
        { id: '1', val: nil },
        { id: '2', val: 'a NULL value' },
        { id: '3', val: nil }
      ]
      result = job_csv(filename: test_csv, incsvopt: { converters: %i[stripplus nulltonil] })
      expect(result).to eq(expected)
    end
    after { File.delete(test_csv) if File.exist?(test_csv) }
  end
end
