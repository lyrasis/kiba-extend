# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Fingerprint::Add do
  before{ Kiba::Extend.config.delim = '|' }
  after{ Kiba::Extend.reset_config }
  let(:input) do
    [
      {a: 'ant', b: 'bee', c: nil, d: 'deer', e: ''}
    ]
  end
  let(:accumulator){ [] }
  let(:test_job){ Helpers::TestJob.new(input: input, accumulator: accumulator, transforms: transforms) }
  let(:result){ test_job.accumulator }

  context 'when delimiter matches possible field value delimiters' do
    let(:transforms) do
      Kiba.job_segment do
        transform Fingerprint::Add, fields: %i[b c d e], delim: '|||', target: :fp
      end
    end

    it 'raises error' do
      expect{ result }.to raise_error(Kiba::Extend::Transforms::Fingerprint::DelimiterCollisionError)
    end

    context 'when override_app_delim_check = true' do
      let(:transforms) do
        Kiba.job_segment do
          transform Fingerprint::Add, fields: %i[b c d e], delim: '|||', target: :fp, override_app_delim_check: true
        end
      end

      let(:expected) do
        [
          {a: 'ant', b: 'bee', c: nil, d: 'deer', e: '', fp: Base64.strict_encode64('bee|||nil|||deer|||empty')}
        ]
      end

      it 'transforms as expected' do
        expect(result).to eq(expected)
      end
    end
  end

  context 'when a field value matches the delimiter' do
  let(:input) do
    [
      {a: 'ant', b: 'be;;;e', c: nil, d: 'deer', e: ''}
    ]
  end

  let(:transforms) do
      Kiba.job_segment do
        transform Fingerprint::Add, fields: %i[b c d e], delim: ';;;', target: :fp
      end
    end

    it 'raises error' do
      expect{ result }.to raise_error(Kiba::Extend::Transforms::Fingerprint::DelimiterInValueError)
    end
  end

  context 'with allowable delimiter' do
    let(:transforms) do
      Kiba.job_segment do
        transform Fingerprint::Add, fields: %i[b c d e], delim: ';;;', target: :fp
      end
    end

    let(:expected) do
      [
        {a: 'ant', b: 'bee', c: nil, d: 'deer', e: '', fp: Base64.strict_encode64('bee;;;nil;;;deer;;;empty')}
      ]
    end

    it 'transforms as expected' do
      expect(result).to eq(expected)
    end
  end
end
