# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Delete::Fields do
  let(:input) do
    [
      {a: '1', b: '2', c: '3'}
    ]
  end
  let(:accumulator){ [] }
  let(:test_job){ Helpers::TestJob.new(input: input, accumulator: accumulator, transforms: transforms) }
  let(:result){ test_job.accumulator }

  context 'with multiple fields in array' do
    let(:transforms) do
      Kiba.job_segment do
        transform Delete::Fields, fields: %i[a c]
      end
    end

    let(:expected) do
      [
        {b: '2'},
      ]
    end

    it 'transforms as expected' do
      expect(result).to eq(expected)
    end
  end

  context 'with single field given' do
    let(:transforms) do
      Kiba.job_segment do
        transform Delete::Fields, fields: :c
      end
    end

    let(:expected) do
      [
        {a: '1', b: '2'},
      ]
    end

    it 'transforms as expected' do
      expect(result).to eq(expected)
    end
  end
end
