# frozen_string_literal: true

require 'marc'
require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Marc::FieldLinkable do

  class Xform
    include Kiba::Extend::Transforms::Marc::FieldLinkable
  end

  subject(:klass){ Xform.new }

  before(:all){ Kiba::Extend::Marc.config.field_tag_target = :sourcefield }
  after(:all){ Kiba::Extend::Marc.reset_config }

  describe '#add_linkage_data' do
    let(:result){ klass.add_linkage_data(field, row) }

    context 'with non-880 tag' do
      let(:field) do
        MARC::DataField.new('700', '1', '2',
                            ['6', '880-02'], ['a', 'name']
                           )
      end
      let(:row){ {marcid: '123', sourcefield: '700'} }

      it 'returns expected' do
        expect(result).to eq({
          marcid: '123',
          linked: true,
          sourcefield: '700',
          linkid: '700-02',
          vernacular: false
        })
      end
    end

    context 'with 880 tag' do
      let(:field) do
        MARC::DataField.new('880', '1', '2',
                            ['6', '700-02'], ['a', 'name']
                           )
      end
      let(:row){ {marcid: '123', sourcefield: '880'} }

      it 'returns expected' do
        expect(result).to eq({
          marcid: '123',
          linked: true,
          sourcefield: '700',
          linkid: '700-02',
          vernacular: true
        })
      end
    end

    context 'with non-linked field' do
      let(:field) do
        MARC::DataField.new('700', '1', '2',
                            ['a', 'name']
                           )
      end
      let(:row){ {marcid: '123', sourcefield: '700'} }

      it 'returns expected' do
        expect(result).to eq({
          marcid: '123',
          linked: false,
          sourcefield: '700',
          linkid: nil,
          vernacular: nil
        })
      end
    end
  end

  describe '#linkage_data' do
    let(:result){ klass.send(:linkage_data, field) }

    context 'with non-880 tag' do
      let(:field) do
        MARC::DataField.new('700', '1', '2',
                            ['6', '880-02'], ['a', 'name']
                           )
      end

      it 'returns expected' do
        expect(result).to eq({
          linked: true,
          sourcefield: '700',
          linkid: '700-02',
          vernacular: false
        })
      end
    end

    context 'with 880 tag' do
      let(:field) do
        MARC::DataField.new('880', '1', '2',
                            ['6', '700-02'], ['a', 'name']
                           )
      end

      it 'returns expected' do
        expect(result).to eq({
          linked: true,
          sourcefield: '700',
          linkid: '700-02',
          vernacular: true
        })
      end
    end
  end

  describe '#linked?' do
    let(:result){ klass.linked?(field) }

    context 'with $6' do
      let(:field) do
        MARC::DataField.new('700', '1', '2',
                            ['6', '880-02'], ['a', 'name']
                           )
      end

      it 'returns true' do
        expect(result).to be true
      end
    end

    context 'without $6' do
      let(:field) do
        MARC::DataField.new('700', '1', '2',
                            ['a', 'name']
                           )
      end

      it 'returns false' do
        expect(result).to be false
      end
    end
  end

  describe '#preferred' do
    after(:each){ Kiba::Extend::Marc.reset_config }

    let(:result){ klass.preferred(rows) }
    let(:tags){ Kiba::Extend::Marc.person_data_tags }
    let(:rec){ get_marc_record(index: 9) }
    let(:rows) do
      klass.select_fields(rec, tags)
        .map{ |fld| klass.add_linkage_data(fld, {}) }
    end

    context 'when preferring vernacular' do
      before(:each){ Kiba::Extend::Marc.config.prefer_vernacular = true }

      it 'returns vernacular field data from pairs' do
        expect(result.length).to eq(13)
      end
    end

    context 'when not preferring vernacular' do
      before(:each){ Kiba::Extend::Marc.config.prefer_vernacular = false }

      it 'returns all field data' do
        expect(result.length).to eq(16)
      end
    end

    context 'when no field data' do
      let(:rec){ get_marc_record(index: 3) }

      it 'returns empty array' do
        expect(result).to eq([])
      end
    end

    context 'when no linked fields' do
      let(:rec){ get_marc_record(index: 0) }

      it 'returns empty array' do
        expect(result.length).to eq(1)
      end
    end
  end

  describe '#select_fields' do
    let(:result){ klass.select_fields(rec, tags) }
    let(:tags){ Kiba::Extend::Marc.person_data_tags }

    context 'with 880 fields' do
      let(:rec){ get_marc_record(index: 9) }

      it 'returns expected' do
        expect(result.length).to eq(16)
      end
    end

    context 'with no 880 fields' do
      let(:rec){ get_marc_record(index: 0) }

      it 'returns expected' do
        expect(result.length).to eq(1)
      end
    end
  end

  describe '#transliterated?' do
    let(:result){ klass.transliterated?(field) }

    context 'with non-880 tag' do
      let(:field) do
        MARC::DataField.new('700', '1', '2',
                            ['6', '880-02'], ['a', 'name']
                           )
      end

      it 'returns true' do
        expect(result).to be true
      end
    end

    context 'with 880 tag' do
      let(:field) do
        MARC::DataField.new('880', '1', '2',
                            ['6', '700-02'], ['a', 'name']
                           )
      end

      it 'returns false' do
        expect(result).to be false
      end
    end
  end

  describe '#vernacular?' do
    let(:result){ klass.vernacular?(field) }

    context 'with non-880 tag' do
      let(:field) do
        MARC::DataField.new('700', '1', '2',
                            ['6', '880-02'], ['a', 'name']
                           )
      end

      it 'returns false' do
        expect(result).to be false
      end
    end

    context 'with 880 tag' do
      let(:field) do
        MARC::DataField.new('880', '1', '2',
                            ['6', '700-02'], ['a', 'name']
                           )
      end

      it 'returns true' do
        expect(result).to be true
      end
    end
  end
end
