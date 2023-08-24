# frozen_string_literal: true

require "marc"
require "spec_helper"

RSpec.describe Kiba::Extend::Transforms::Marc::FieldLinkable do
  class Xform
    include Kiba::Extend::Transforms::Marc::FieldLinkable
  end

  subject(:klass) { Xform.new }

  before(:each) { Kiba::Extend::Marc.config.field_tag_target = :sourcefield }
  after(:each) { Kiba::Extend::Marc.reset_config }

  describe "#select_fields" do
    let(:result) { klass.select_fields(rec, tags) }
    let(:tags) { Kiba::Extend::Marc.person_data_tags }

    context "with 880 fields and prefer vernacular" do
      let(:rec) { get_marc_record(index: 9) }

      it "returns expected fields" do
        expect(result.length).to eq(13)
      end

      it "converts 880 tags to linked field tags" do
        expect(result.select { |fld| fld.tag == "880" }).to be_empty
        expect(result[-1].tag).to eq("100")
      end
    end

    context "with 880 fields and do not prefer vernacular" do
      before(:each) { Kiba::Extend::Marc.config.prefer_vernacular = false }
      let(:rec) { get_marc_record(index: 9) }

      it "returns expected fields" do
        expect(result.length).to eq(16)
      end

      it "converts 880 tags to linked field tags" do
        expect(result.select { |fld| fld.tag == "880" }).to be_empty
        expect(result.count { |fld| fld.tag == "100" }).to eq(2)
      end
    end

    context "with no 880 fields" do
      let(:rec) { get_marc_record(index: 0) }

      it "returns expected" do
        expect(result.length).to eq(1)
      end
    end

    context "with no matching fields" do
      let(:rec) { get_marc_record(index: 3) }

      it "returns expected" do
        expect(result).to eq([])
      end
    end
  end

  # -=-=-=-
  # Tests of private methods used for dev/refactoring
  # -=-=-=-

  # describe '#linked?' do
  #   let(:result){ klass.send(:linked?, field) }

  #   context 'with $6' do
  #     let(:field) do
  #       MARC::DataField.new('700', '1', '2',
  #                           ['6', '880-02'], ['a', 'name']
  #                          )
  #     end

  #     it 'returns true' do
  #       expect(result).to be true
  #     end
  #   end

  #   context 'without $6' do
  #     let(:field) do
  #       MARC::DataField.new('700', '1', '2',
  #                           ['a', 'name']
  #                          )
  #     end

  #     it 'returns false' do
  #       expect(result).to be false
  #     end
  #   end
  # end

  # describe '#add_linkage_data' do
  #   let(:result){ klass.send(:add_linkage_data, field) }

  #   context 'with non-880 tag' do
  #     let(:field) do
  #       MARC::DataField.new('700', '1', '2',
  #                           ['6', '880-02'], ['a', 'name']
  #                          )
  #     end

  #     it 'returns expected' do
  #       expect(result).to eq({
  #         datafield: field,
  #         linked: true,
  #         linkid: '700-02',
  #         vernacular: false,
  #         sourcefield: '700'
  #       })
  #     end
  #   end

  #   context 'with 880 tag' do
  #     let(:field) do
  #       MARC::DataField.new('880', '1', '2',
  #                           ['6', '700-02'], ['a', 'name']
  #                          )
  #     end

  #     it 'returns expected' do
  #       expect(result).to eq({
  #         datafield: field,
  #         linked: true,
  #         sourcefield: '700',
  #         linkid: '700-02',
  #         vernacular: true
  #       })
  #     end
  #   end

  #   context 'with non-linked field' do
  #     let(:field) do
  #       MARC::DataField.new('700', '1', '2',
  #                           ['a', 'name']
  #                          )
  #     end

  #     it 'returns expected' do
  #       expect(result).to eq({
  #         datafield: field,
  #         linked: false,
  #         sourcefield: '700',
  #         linkid: nil,
  #         vernacular: nil
  #       })
  #     end
  #   end
  # end

  # describe '#linkage_data' do
  #   let(:result){ klass.send(:linkage_data, field) }

  #   context 'with non-880 tag' do
  #     let(:field) do
  #       MARC::DataField.new('700', '1', '2',
  #                           ['6', '880-02'], ['a', 'name']
  #                          )
  #     end

  #     it 'returns expected' do
  #       expect(result).to eq({
  #         linked: true,
  #         sourcefield: '700',
  #         linkid: '700-02',
  #         vernacular: false
  #       })
  #     end
  #   end

  #   context 'with 880 tag' do
  #     let(:field) do
  #       MARC::DataField.new('880', '1', '2',
  #                           ['6', '700-02'], ['a', 'name']
  #                          )
  #     end

  #     it 'returns expected' do
  #       expect(result).to eq({
  #         linked: true,
  #         sourcefield: '700',
  #         linkid: '700-02',
  #         vernacular: true
  #       })
  #     end
  #   end
  # end

  # describe '#transliterated?' do
  #   let(:result){ klass.send(:transliterated?, field) }

  #   context 'with non-880 tag' do
  #     let(:field) do
  #       MARC::DataField.new('700', '1', '2',
  #                           ['6', '880-02'], ['a', 'name']
  #                          )
  #     end

  #     it 'returns true' do
  #       expect(result).to be true
  #     end
  #   end

  #   context 'with 880 tag' do
  #     let(:field) do
  #       MARC::DataField.new('880', '1', '2',
  #                           ['6', '700-02'], ['a', 'name']
  #                          )
  #     end

  #     it 'returns false' do
  #       expect(result).to be false
  #     end
  #   end
  # end

  # describe '#vernacular?' do
  #   let(:result){ klass.send(:vernacular?, field) }

  #   context 'with non-880 tag' do
  #     let(:field) do
  #       MARC::DataField.new('700', '1', '2',
  #                           ['6', '880-02'], ['a', 'name']
  #                          )
  #     end

  #     it 'returns false' do
  #       expect(result).to be false
  #     end
  #   end

  #   context 'with 880 tag' do
  #     let(:field) do
  #       MARC::DataField.new('880', '1', '2',
  #                           ['6', '700-02'], ['a', 'name']
  #                          )
  #     end

  #     it 'returns true' do
  #       expect(result).to be true
  #     end
  #   end
  # end
end
