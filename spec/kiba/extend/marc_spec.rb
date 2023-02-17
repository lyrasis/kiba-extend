# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Marc do
  describe '#linked_fields' do
    let(:marcpath){ File.join(fixtures_dir, 'harvard_open_data.mrc') }
    let(:result){ Kiba::Extend::Marc.linked_fields(rec, tag) }

    context 'when linked field present' do
      let(:rec){ get_marc_record(marcpath, 6) }
      let(:tag){ '245' }

      it 'returns Array of 880/245 field(s)' do
        expect(result).to be_a(Array)
        expect(result.first).to be_a(MARC::DataField)
        expect(result.length).to eq(1)
      end
    end
  end
end
