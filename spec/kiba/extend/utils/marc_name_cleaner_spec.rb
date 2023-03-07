# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Utils::MarcNameCleaner do
  subject(:cleaner){ described_class.new }

  describe '#call' do
    it 'returns expected' do
      expectations = {
        'Kirmse, Marguerite, 1885-1954,'=>'Kirmse, Marguerite, 1885-1954',
        'Stowe, Harriet Beecher, 1811-1896.'=>'Stowe, Harriet Beecher, 1811-1896',
        'Authors Club (New York, N.Y.)'=>'Authors Club (New York, N.Y.)',
        'Thomas, Alan G.'=>'Thomas, Alan G.',
        'Okes, Nicholas,.'=>'Okes, Nicholas'
      }
      result = expectations.keys
        .map{ |val| cleaner.call(val) }

      expect(result).to eq(expectations.values)
    end
  end
end
