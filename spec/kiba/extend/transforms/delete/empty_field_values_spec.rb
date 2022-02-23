# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Delete::EmptyFieldValues do
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

  context 'with default usenull argument' do
    let(:transforms) do
      Kiba.job_segment do
        transform Delete::EmptyFieldValues, fields: [:data], sep: ';'
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
        transform Delete::EmptyFieldValues, fields: [:data], sep: ';', usenull: true
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
  end
end
