# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Merge::ConstantValue do
  let(:transform){ described_class.new(target: :species, value: 'guinea fowl') }
  
  let(:results){ rows.map{ |row| transform.process(row) } }
  let(:expected) do
    [
      {name: 'Weddy', sex: 'm', source: 'adopted', species: 'guinea fowl' },
      {name: 'Kernel', sex: 'f', source: 'adopted', species: 'guinea fowl' }
    ]
  end

  context 'target field exists and is populated' do
    let(:rows) do
      [
        {name: 'Weddy', sex: 'm', source: 'adopted'},
        {name: 'Kernel', sex: 'f', source: 'adopted', species: 'Numida meleagris'}
      ]
    end

    it 'transforms and warns as expected', :aggregate_failures do
      msg = "#{Kiba::Extend.warning_label}: Any values in existing `species` field will be overwritten with `guinea fowl`"
      expect(transform).to receive(:warn).with(msg)
      expect(results).to eq(expected)
    end
  end

  context 'target field exists and is not populated' do
    let(:rows) do
      [
        {name: 'Weddy', sex: 'm', source: 'adopted'},
        {name: 'Kernel', sex: 'f', source: 'adopted', species: ''}
      ]
    end

    it 'transforms and does not warn as expected', :aggregate_failures do
      expect(transform).not_to receive(:warn)
      expect(results).to eq(expected)
    end
  end
end
