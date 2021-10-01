# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Destinations::CSV do
  TEST_FILENAME = 'output.csv'
  def run_job(input)
    job = Kiba.parse do
      source Kiba::Common::Sources::Enumerable, input
      destination Kiba::Extend::Destinations::CSV, filename: TEST_FILENAME, initial_headers: %i[y z]
    end

    Kiba.run(job)

    IO.read(TEST_FILENAME)
  end

  after(:each){ File.delete(TEST_FILENAME) if File.exist?(TEST_FILENAME) }

  context 'when intial headers present' do
    let(:input) do
      [
        {a: 'and', y: 'yak', z: 'zebra'},
        {a: 'apple', y: 'yarrow', z: 'zizia'}
      ]
    end
    let(:expected) do
      "y,z,a\nyak,zebra,and\nyarrow,zizia,apple\n"
    end
    it 'produces CSV as expected' do
      expect(run_job(input)).to eq(expected)
    end
  end

  context 'when intial headers specified but not present' do
    let(:input) do
      [
        {a: 'and', z: 'zebra'},
        {a: 'apple', z: 'zizia'}
      ]
    end
    let(:expected) do
      "z,a\nzebra,and\nzizia,apple\n"
    end
    it 'produces CSV as expected' do
      expect(run_job(input)).to eq(expected)
    end
    it 'writes warning to STDOUT' do
      msg = 'Output data does not contain specified initial header: y'
      expect { run_job(input) }.to output(/#{msg}/).to_stdout
    end
  end
end

