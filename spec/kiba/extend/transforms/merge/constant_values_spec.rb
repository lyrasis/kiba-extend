# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Merge::ConstantValues do
  let(:transform) do
    described_class.new(
      constantmap: {
        species_common: 'guinea fowl',
        species_binomial: 'Numida meleagris'
      }
    )
  end
  
  let(:rows) do
    [
      {name: 'Weddy'},
      {name: 'Kernel', species: 'Numida meleagris'}
    ]
  end
  let(:results){ rows.map{ |row| transform.process(row) } }
  let(:expected) do
    [
      {name: 'Weddy', species_common: 'guinea fowl', species_binomial: 'Numida meleagris' },
      {name: 'Kernel', species: 'Numida meleagris', species_common: 'guinea fowl', species_binomial: 'Numida meleagris' }
    ]
  end

  it 'transforms as expected' do
    expect(results).to eq(expected)
  end
end
