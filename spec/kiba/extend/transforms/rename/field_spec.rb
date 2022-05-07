# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Rename::Field do
  let(:transform){ Rename::Field.new(from: :sex, to: :gender) }
  let(:results){ rows.map{ |row| transform.process(row) } }

  context 'when from field exists' do
    let(:rows) do
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
      expect(results).to eq(expected)
    end
  end

  context 'when to field already exists' do
    let(:rows) do
      [
        {name: 'Weddy', sex: 'm', gender: 'nonbinary'}
      ]
    end

    let(:expected) do
      [
        { name: 'Weddy', gender: 'm' },
      ]
    end
    
    it 'renames field and warns of replacement', :aggregate_failures do
      msg = "#{Kiba::Extend.warning_label}: Renaming `sex` to `gender` overwrites existing `gender` field data"
      expect(transform).to receive(:warn).with(msg)
      expect(results).to eq(expected)
    end
  end

  context 'when from field does not exist' do
    let(:rows) do
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
      msg = "#{Kiba::Extend.warning_label}: Cannot rename field: `sex` does not exist in row"
      expect(transform).to receive(:warn).with(msg)
      expect(results).to eq(expected)

    end
  end
end

