# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Fingerprint::Decode do
  let(:input) do
    [
      {a: 'ant', b: 'bee', c: nil, d: 'deer', e: '', fp: 'YmVlOzs7bmlsOzs7ZGVlcjs7O2VtcHR5'}
    ]
  end
  let(:accumulator){ [] }
  let(:test_job){ Helpers::TestJob.new(input: input, accumulator: accumulator, transforms: transforms) }
  let(:result){ test_job.accumulator }

  context 'with defaults' do
    let(:transforms) do
      Kiba.job_segment do
        transform Fingerprint::Decode, fingerprint: :fp, source_fields: %i[b c d e], delim: ';;;', prefix: 'fp'
      end
    end

    let(:expected) do
      [
        {a: 'ant', b: 'bee', c: nil, d: 'deer', e: '', fp: 'YmVlOzs7bmlsOzs7ZGVlcjs7O2VtcHR5',
         fp_b: 'bee', fp_c: nil, fp_d: 'deer', fp_e: ''}
      ]
    end

    it 'transforms as expected' do
      expect(result).to eq(expected)
    end
  end

  context 'with delete_fp = true' do
    let(:transforms) do
      Kiba.job_segment do
        transform Fingerprint::Decode, fingerprint: :fp, source_fields: %i[b c d e], delim: ';;;', prefix: 'fp', delete_fp: true
      end
    end

    let(:expected) do
      [
        {a: 'ant', b: 'bee', c: nil, d: 'deer', e: '',
         fp_b: 'bee', fp_c: nil, fp_d: 'deer', fp_e: ''}
      ]
    end

    it 'transforms as expected' do
      expect(result).to eq(expected)
    end
  end

  context 'with field value containing the delimiter' do
    let(:input) do
      [
        {a: 'ant', b: 'be;;;e', c: nil, d: 'deer', e: '', fp: 'YmU7OztlOzs7bmlsOzs7ZGVlcjs7O2VtcHR5'}
      ]
    end

    let(:transforms) do
      Kiba.job_segment do
        transform Fingerprint::Decode, fingerprint: :fp, source_fields: %i[b c d e], delim: ';;;', prefix: 'fp', delete_fp: true
      end
    end

    let(:expected) do
      [
        {a: 'ant', b: 'be;;;e', c: nil, d: 'deer', e: '',
         fp_b: 'be', fp_c: 'e', fp_d: nil, fp_e: 'deer'}
      ]
    end

    it 'transforms as expected' do
      expect(result).to eq(expected)
    end
  end

  context 'with field value containing non-ASCII characters' do
    let(:input) do
      [
        {fp: 'YTs7O0hhZ3N0csO2bTs7O25pbA=='}
      ]
    end

    let(:transforms) do
      Kiba.job_segment do
        transform Fingerprint::Decode, fingerprint: :fp, source_fields: %i[b c d], delim: ';;;', prefix: 'fp', delete_fp: true
      end
    end

    let(:expected) do
      [
        {fp_b: 'a', fp_c: 'Hagström', fp_d: nil}
      ]
    end

    it 'transforms as expected' do
      expect(result).to eq(expected)
    end
  end
end
