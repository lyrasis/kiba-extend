# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Delete::EmptyFieldValues do
  before{ Kiba::Extend.config.delim = '|' }
  
  let(:input) do
    [
      {data: 'abc;;;d e f'},
      {data: ';;abc'},
      {data: 'def;;;;'},
      {data: ';;;;;'},
      {data: ';;;%NULLVALUE%;;'},
      {data: ''},
      {data: nil}
    ]
  end
  let(:accumulator){ [] }
  let(:test_job){ Helpers::TestJob.new(input: input, accumulator: accumulator, transforms: transforms) }
  let(:result){ test_job.accumulator }

  context 'no delimiter given' do
  let(:input) do
    [
      {data: 'abc|||d e f'},
      {data: '||abc'},
      {data: 'def||||'},
      {data: '|||||'},
      {data: '|||%NULLVALUE%||'},
      {data: ''},
      {data: nil}
    ]
  end
    let(:transforms) do
      Kiba.job_segment do
        transform Delete::EmptyFieldValues, fields: :data
      end
    end

    let(:expected) do
      [
        {data: 'abc|d e f'},
        {data: 'abc'},
        {data: 'def'},
        {data: ''},
        {data: '%NULLVALUE%'},
        {data: ''},
        {data: nil}
      ]
    end

    it 'transforms as expected' do
      expect(result).to eq(expected)
    end
  end

  context 'with default usenull argument' do
    let(:transforms) do
      Kiba.job_segment do
        transform Delete::EmptyFieldValues, fields: [:data], delim: ';'
      end
    end

    let(:expected) do
      [
        {data: 'abc;d e f'},
        {data: 'abc'},
        {data: 'def'},
        {data: ''},
        {data: '%NULLVALUE%'},
        {data: ''},
        {data: nil}
      ]
    end

    it 'transforms as expected' do
      expect(result).to eq(expected)
    end
  end

  context 'with usenull = true' do
    let(:transforms) do
      Kiba.job_segment do
        transform Delete::EmptyFieldValues, fields: [:data], delim: ';', usenull: true
      end
    end

    let(:expected) do
      [
        {data: 'abc;d e f'},
        {data: 'abc'},
        {data: 'def'},
        {data: ''},
        {data: ''},
        {data: ''},
        {data: nil}
      ]
    end

    it 'transforms as expected' do
      expect(result).to eq(expected)
    end

    context 'with sep given' do
      let(:transforms) do
        Kiba.job_segment do
          transform Delete::EmptyFieldValues, fields: [:data], sep: ';', usenull: true
        end
      end

      it 'transforms as expected'  do
        expect(result).to eq(expected)
      end

      it 'puts warning to STDOUT' do
        msg = %Q[#{Kiba::Extend.warning_label}: The `sep` keyword is being deprecated in a future version. Change it to `delim` in your ETL code.\n]
        expect{ result }.to output(msg).to_stdout
      end
    end

    context 'when fields = :all' do
      let(:input) do
        [
          {data: 'abc|||d e f', foo: 'abc|||d e f'},
        ]
      end
      let(:transforms) do
        Kiba.job_segment do
          transform Delete::EmptyFieldValues, fields: :all
        end
      end

      let(:expected) do
        [
          {data: 'abc|d e f', foo: 'abc|d e f'}
        ]
      end

      it 'transforms as expected' do
        expect(result).to eq(expected)
      end
    end
  end
end
