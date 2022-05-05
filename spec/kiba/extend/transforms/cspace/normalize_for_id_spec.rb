# frozen_string_literal: true

RSpec.describe Kiba::Extend::Transforms::Cspace::NormalizeForID do
  let(:accumulator){ [] }
  let(:test_job){ Helpers::TestJob.new(input: input, accumulator: accumulator, transforms: transforms) }
  let(:result){ test_job.accumulator }

  let(:input) do
    [
      {subject: 'Oświęcim (Poland)'},
      {subject: 'Oswiecim, Poland'},
      {subject: 'Iași, Romania'},
      {subject: 'Iasi, Romania'},
      {subject: 'a|b'}
    ]
  end

  context 'when multival = false' do
    let(:expected) do
      [
        { subject: 'Oświęcim (Poland)', norm: 'oswiecimpoland' },
        { subject: 'Oswiecim, Poland', norm: 'oswiecimpoland' },
        { subject: 'Iași, Romania', norm: 'iasiromania' },
        { subject: 'Iasi, Romania', norm: 'iasiromania' },
        { subject: 'a|b', norm: 'ab' }
      ]
    end

    let(:transforms) do
      Kiba.job_segment do
        transform Cspace::NormalizeForID, source: :subject, target: :norm
      end
    end
    
    it 'normalizes as expected' do
      expect(result).to eq(expected)
    end
  end

  context 'when multival = true' do
    let(:expected) do
      [
        { subject: 'Oświęcim (Poland)', norm: 'oswiecimpoland' },
        { subject: 'Oswiecim, Poland', norm: 'oswiecimpoland' },
        { subject: 'Iași, Romania', norm: 'iasiromania' },
        { subject: 'Iasi, Romania', norm: 'iasiromania' },
        { subject: 'a|b', norm: 'a|b' }
      ]
    end

    let(:transforms) do
      Kiba.job_segment do
        transform Cspace::NormalizeForID, source: :subject, target: :norm, multival: true, delim: '|'
      end
    end
    
    it 'normalizes as expected' do
      expect(result).to eq(expected)
    end
  end
end
