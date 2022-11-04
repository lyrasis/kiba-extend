# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Explode::RowsFromMultivalField do
  let(:accumulator){ [] }
  let(:test_job){ Helpers::TestJob.new(input: input, accumulator: accumulator, transforms: transforms) }
  let(:result){ test_job.accumulator }

  let(:input) do
    [
      {r1: 'a;b', r2: 'foo;bar'}
    ]
  end

  let(:transforms) do
    Kiba.job_segment do
      transform Explode::RowsFromMultivalField, field: :r1, delim: ';'
    end
  end

  let(:expected) do
    [
      { r1: 'a', r2: 'foo;bar' },
      { r1: 'b', r2: 'foo;bar' }
    ]
  end

  it 'transforms as expected' do
    expect(result).to eq(expected)
  end

  context 'when delim not given' do
    before{ Kiba::Extend.config.delim = ';' }
    after{ Kiba::Extend.reset_config }
    let(:transforms) do
      Kiba.job_segment do
        transform Explode::RowsFromMultivalField, field: :r1
      end
    end

    it 'uses Kiba::Extend.delim value' do
      expect(result).to eq(expected)
    end
  end
end
