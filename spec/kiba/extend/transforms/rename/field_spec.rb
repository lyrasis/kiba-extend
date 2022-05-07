# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Rename::Field do
  let(:accumulator){ [] }
  let(:test_job){ Helpers::TestJob.new(input: input, accumulator: accumulator, transforms: transforms) }
  let(:result){ test_job.accumulator }

  let(:transforms) do
    Kiba.job_segment do
      transform Rename::Field, from: :sex, to: :gender
    end
  end

  context 'when target field exists' do
    let(:input) do
      [
        {name: 'Weddy', sex: 'm'},
        {name: 'Kernel', sex: 'f'}
      ]
    end

    let(:expected) do
      [
        { name: 'Weddy', gender: 'm' },
        { name: 'Kernel', gender: 'f' }
      ]
    end
    
    it 'renames field' do
      expect(result).to eq(expected)
    end
  end

  context 'when target field does not exist' do
    let(:input) do
      [
        {name: 'Weddy'},
      ]
    end

    let(:expected) do
      [
        { name: 'Weddy'}
      ]
    end
    
    it 'returns row unchanged and warns', :aggregate_failures do
      expect(result).to eq(expected)
      msg = "#{Kiba::Extend.warning_label}: Cannot rename field: `sex` does not exist in row"
      xform = Rename::Field.new(from: :sex, to: :gender)
      expect(xform).to receive(:warn).with(msg)
      xform.process(input.first)
    end
  end
end

