# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Cspace do
  let(:accumulator){ [] }
  let(:test_job){ Helpers::TestJob.new(input: input, accumulator: accumulator, transforms: transforms) }
  let(:result){ test_job.accumulator }

  describe 'ConvertToID' do
    let(:input){ [{name: 'Weddy1'}] }
    let(:expected){ [{ name: 'Weddy1', sid: 'Weddy13761760099' }] }
    let(:transforms) do
      Kiba.job_segment do
        transform Cspace::ConvertToID, source: :name, target: :sid
      end
    end
    
    it 'inserts CS shortID of given source into target' do
      expect(result).to eq(expected)
    end
  end

  describe 'FlagInvalidCharacters' do
    before do
      @old = Cspace.const_get('BRUTEFORCE')
      Cspace.const_set('BRUTEFORCE', {})
    end
    after do
      Cspace.const_set('BRUTEFORCE', @old)
    end

    let(:input) do
      [
        {subject: 'Iași, Romania'},
        {subject: 'Iasi, Romania'}
      ]
    end

    let(:expected) do
      [
        { subject: 'Iași, Romania', flag: 'Ia%INVCHAR%i, Romania' },
        { subject: 'Iasi, Romania', flag: nil }
      ]
    end
    
    let(:transforms) do
      Kiba.job_segment do
        transform Cspace::FlagInvalidCharacters, check: :subject, flag: :flag
      end
    end
    
    it 'adds column containing field value with invalid chars replaced with ?' do
      expect(result).to eq(expected)
    end
  end

  describe 'NormalizeForID' do
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
end
