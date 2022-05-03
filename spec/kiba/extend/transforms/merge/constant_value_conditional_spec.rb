# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Merge::ConstantValueConditional do
  let(:accumulator){ [] }
  let(:test_job){ Helpers::TestJob.new(input: input, accumulator: accumulator, transforms: transforms) }
  let(:result){ test_job.accumulator }


  let(:transforms) do
    Kiba.job_segment do
      transform Merge::ConstantValueConditional,
        fieldmap: { reason: 'gift' },
        conditions: {
          include: {
            field_equal: { fieldsets: [
              {
                matches: [
                  ['row::note', 'revalue::[Gg]ift'],
                  ['row::note', 'revalue::[Dd]onation']
                ]
              }
            ] }
          }
        }
    end
  end
  
  context 'when row meets criteria' do
    let(:input) do
      [
        {reason: nil, note: 'Gift'},
        {reason: nil, note: 'donation'}
      ]
    end

    let(:expected) do
      [
        { reason: 'gift', note: 'Gift' },
        { reason: 'gift', note: 'donation' }
      ]
    end

    it 'merges constant data values into specified field' do
      expect(result).to eq(expected)
    end

    context 'when target field has a pre-existing value' do
      let(:input) do
        [
          {reason: 'donation', note: 'Gift'}
        ]
      end
      let(:expected) do
        [
          { reason: 'gift', note: 'Gift' }
        ]
      end
      
      it 'that value is overwritten by the specified constant value' do
        expect(result).to eq(expected)
      end
    end
  end

  context 'when row does not meet criteria' do
    context 'and target field already exists in row' do
      let(:input) do
        [
          {reason: 'misc', note: 'Something else'}
        ]
      end
      let(:expected) do
        [
          {reason: 'misc', note: 'Something else' }
        ]
      end

      it 'target field value stays the same' do
        expect(result).to eq(expected)
      end
    end

    context 'and target field does not exist in row' do
      let(:input) do
        [
          {note: 'Something else'}
        ]
      end
      let(:expected) do
        [
          { reason: nil, note: 'Something else' }
        ]
      end

      it 'target field is added to row, with nil value' do
        expect(result).to eq(expected)
      end
    end
  end
end
