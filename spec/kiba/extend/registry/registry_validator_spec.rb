# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength
RSpec.describe 'Kiba::Extend::Registry::RegistryValidator' do
  before(:context) do
    Kiba::Extend.config.registry = Kiba::Extend::Registry::FileRegistry.new
    prepare_registry
  end
  let(:validator) { Kiba::Extend::Registry::RegistryValidator.new }

  describe '#valid?' do
    let(:result) { validator.valid? }
    it 'reports invalid entries' do
      expect(result).to be false
    end
  end
end
# rubocop:enable Metrics/BlockLength
