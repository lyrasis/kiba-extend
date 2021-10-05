# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Count::FieldValues do
  let(:accumulator){ [] }
  let(:test_job){ Helpers::TestJob.new(input: input, accumulator: accumulator, transforms: transforms) }
  let(:result){ test_job.accumulator }

  let(:input) do
    [
      {name: 'Weddy'},
      {name: 'NULL'},
      {name: ''},
      {name: nil},
      {name: 'Earlybird;Divebomber'},
      {name: ';Niblet'},
      {name: 'Hunter;'},
      {name: 'NULL;Earhart'},
      {name: ';'},
      {name: 'NULL;NULL'}
    ]
  end

  context 'with no placeholder (default)' do
    context 'when count_empty = false (default)' do
      let(:transforms) do
        Kiba.job_segment do
          transform Count::FieldValues, field: :name, target: :ct, delim: ';'
        end
      end
      
      let(:expected) do
        [
          {name: 'Weddy', ct: '1'},
          {name: 'NULL', ct: '1'},
          {name: '', ct: '0'},
          {name: nil, ct: '0'},
          {name: 'Earlybird;Divebomber', ct: '2'},
          {name: ';Niblet', ct: '1'},
          {name: 'Hunter;', ct: '1'},
          {name: 'NULL;Earhart', ct: '2'},
          {name: ';', ct: '0'},
          {name: 'NULL;NULL', ct: '2'}
        ]
      end
      
      it 'adds counts as expected' do
        expect(result).to eq(expected)
      end
    end

    context 'when count_empty = true' do
      let(:transforms) do
        Kiba.job_segment do
          transform Count::FieldValues, field: :name, target: :ct, delim: ';', count_empty: true
        end
      end
      
      let(:expected) do
        [
          {name: 'Weddy', ct: '1'},
          {name: 'NULL', ct: '1'},
          {name: '', ct: '0'},
          {name: nil, ct: '0'},
          {name: 'Earlybird;Divebomber', ct: '2'},
          {name: ';Niblet', ct: '2'},
          {name: 'Hunter;', ct: '2'},
          {name: 'NULL;Earhart', ct: '2'},
          {name: ';', ct: '2'},
          {name: 'NULL;NULL', ct: '2'}
        ]
      end
      
      it 'adds counts as expected' do
        expect(result).to eq(expected)
      end
    end
  end

  context 'with placeholder' do
    context 'when count_empty = false (default)' do
      let(:transforms) do
        Kiba.job_segment do
          transform Count::FieldValues, field: :name, target: :ct, delim: ';', placeholder: 'NULL'
        end
      end
      
      let(:expected) do
        [
          {name: 'Weddy', ct: '1'},
          {name: 'NULL', ct: '0'},
          {name: '', ct: '0'},
          {name: nil, ct: '0'},
          {name: 'Earlybird;Divebomber', ct: '2'},
          {name: ';Niblet', ct: '1'},
          {name: 'Hunter;', ct: '1'},
          {name: 'NULL;Earhart', ct: '1'},
          {name: ';', ct: '0'},
          {name: 'NULL;NULL', ct: '0'}
        ]
      end
      
      it 'adds counts as expected' do
        expect(result).to eq(expected)
      end
    end

    context 'when count_empty = true' do
      let(:transforms) do
        Kiba.job_segment do
          transform Count::FieldValues, field: :name, target: :ct, delim: ';', placeholder: 'NULL', count_empty: true
        end
      end
      
      let(:expected) do
        [
          {name: 'Weddy', ct: '1'},
          {name: 'NULL', ct: '1'},
          {name: '', ct: '0'},
          {name: nil, ct: '0'},
          {name: 'Earlybird;Divebomber', ct: '2'},
          {name: ';Niblet', ct: '2'},
          {name: 'Hunter;', ct: '2'},
          {name: 'NULL;Earhart', ct: '2'},
          {name: ';', ct: '2'},
          {name: 'NULL;NULL', ct: '2'}
        ]
      end
      
      it 'adds counts as expected' do
        expect(result).to eq(expected)
      end
    end
  end
end
