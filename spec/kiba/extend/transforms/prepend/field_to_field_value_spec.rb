# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Prepend::FieldToFieldValue do
  let(:accumulator){ [] }
  let(:test_job){ Helpers::TestJob.new(input: input, accumulator: accumulator, transforms: transforms) }
  let(:result){ test_job.accumulator }

  let(:input) do
    [
      {name: 'Weddy', prependval: 'm'},
      {name: nil, prependval: 'u'},
      {name: '', prependval: 'u'},
      {name: 'Kernel', prependval: nil},
      {name: 'Divebomber|Hunter', prependval: 'm'},
      {name: 'Divebomber|Niblet|Keet', prependval: 'm|f'},
      {name: '|Niblet', prependval: 'm|f'},
    ]
  end
  
  context 'when called with multival prepend field and no mvdelim' do
    let(:transforms) do
      Kiba.job_segment do
        transform Prepend::FieldToFieldValue,
          target_field: :name,
          prepended_field: :prependval,
          sep: ':',
          multivalue_prepended_field: true
      end
    end
    
    it 'raises MissingDelimiterError' do
      msg = 'You must provide an mvdelim string if multivalue_prepended_field is true'
      expect { result }.to raise_error(msg)
    end
  end

  context 'when delete_prepended = false' do
    let(:transforms) do
      Kiba.job_segment do
        transform Prepend::FieldToFieldValue,
          target_field: :name,
          prepended_field: :prependval,
          sep: ': ',
          mvdelim: '|'
      end
    end

    let(:expected) do
      [
        {name: 'm: Weddy', prependval: 'm'},
        {name: nil, prependval: 'u'},
        {name: '', prependval: 'u'},
        {name: 'Kernel', prependval: nil},
        {name: 'm: Divebomber|m: Hunter', prependval: 'm'},
        {name: 'm|f: Divebomber|m|f: Niblet|m|f: Keet', prependval: 'm|f'},
        {name: '|m|f: Niblet', prependval: 'm|f'},
      ]
    end
    
    it 'transforms as expected' do
      expect(result).to eq(expected)
    end
  end

  context 'when delete_prepended = true' do
    let(:transforms) do
      Kiba.job_segment do
        transform Prepend::FieldToFieldValue,
          target_field: :name,
          prepended_field: :prependval,
          sep: ': ',
          mvdelim: '|',
          delete_prepended: true
      end
    end

    let(:expected) do
      [
        {name: 'm: Weddy'},
        {name: nil},
        {name: ''},
        {name: 'Kernel'},
        {name: 'm: Divebomber|m: Hunter'},
        {name: 'm|f: Divebomber|m|f: Niblet|m|f: Keet'},
        {name: '|m|f: Niblet'},
      ]
    end
    
    it 'transforms as expected' do
      expect(result).to eq(expected)
    end
  end

  context 'when multivalue_prepended_field = true' do
    let(:transforms) do
      Kiba.job_segment do
        transform Prepend::FieldToFieldValue,
          target_field: :name,
          prepended_field: :prependval,
          sep: ': ',
          mvdelim: '|',
          delete_prepended: true,
          multivalue_prepended_field: true
      end
    end

    let(:expected) do
      [
        {name: 'm: Weddy'},
        {name: nil},
        {name: ''},
        {name: 'Kernel'},
        {name: 'm: Divebomber|Hunter'},
        {name: 'm: Divebomber|f: Niblet|Keet'},
        {name: '|f: Niblet'},
      ]
    end
    
    it 'transforms as expected' do
      expect(result).to eq(expected)
    end
  end
end
