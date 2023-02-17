# frozen_string_literal: true

require 'marc'
require 'spec_helper'

RSpec.describe Kiba::Extend::Utils::MarcIdExtractor do
  subject(:xform){ described_class.new }
  after(:each){ Kiba::Extend::Marc.reset_config }

  describe '.new' do
    context 'with field: 001 and subfield: a'  do
      before{ Kiba::Extend::Marc.config.id_subfield = 'a' }

      it 'raises ControlFieldsDoNotHaveSubfieldsError' do
        expect{ xform }.to raise_error(
          Kiba::Extend::Utils::MarcIdExtractor::ControlFieldsDoNotHaveSubfieldsError
          )
      end
    end
  end

  describe '#call' do
    let(:result){ xform.call(record) }

    context 'with field: 001'  do
      let(:record){ get_marc_record(index: 3) }

      it 'returns expected' do
        expect(result).to eq('008000411-3')
      end
    end

    context 'with field: 999'  do
      before{ Kiba::Extend::Marc.config.id_tag = '999' }
      let(:record){ get_marc_record(index: 3) }

      it 'returns expected' do
        expect(result).to be_nil
      end
    end

    context 'with complex multiple complex 035s' do
      before{ Kiba::Extend::Marc.config.id_tag = '035' }
      let(:record){ get_marc_record(index: 0) }
      # 035    $a (OCoLC)01484180 $z (OCoLC)35680312 $z (OCoLC)41668919
      # 035    $a (OCoLC)ocm01484180
      # 035    $a (EXLNZ-01GALI_NETWORK)9911119856302931
      # 035    $a (01GALI_KS)99705693902954

      context 'with taking prefixed OCLC num from $a' do
        before do
          Kiba::Extend::Marc.config.id_subfield = 'a'
          Kiba::Extend::Marc.config.id_subfield_selector = ->(value) do
            value.match?(/^\(OCoLC\)\D/)
          end
          Kiba::Extend::Marc.config.id_value_formatter = ->(values) do
            values.first
              .delete_prefix('(OCoLC)')
              .strip
          end
        end

        it 'returns expected' do
          expect(result).to eq('ocm01484180')
        end
      end

      context 'with complicated multiple value processing' do
        before do
          Kiba::Extend::Marc.config.id_subfield = 'a'
          Kiba::Extend::Marc.config.id_field_selector = nil
          Kiba::Extend::Marc.config.id_value_formatter = ->(values) do
            values.map{ |val| val.sub(/^\(.*\)/, '') }
              .map{ |val| val.sub(/^\D+/, '') }
              .map(&:strip)
              .uniq
              .join('.')
          end
        end

        it 'returns expected' do
          expect(result).to eq('01484180.9911119856302931.99705693902954')
        end
      end

      context 'when nothing matches criteria' do
        before do
          Kiba::Extend::Marc.config.id_subfield = 'a'
          Kiba::Extend::Marc.config.id_subfield_selector = ->(value) do
            value.match?(/^\(OCoLC\)ocn/)
          end
          Kiba::Extend::Marc.config.id_value_formatter = ->(values) do
            values.first
              .delete_prefix('(OCoLC)')
              .strip
          end
        end

        it 'returns expected' do
          expect(result).to be_nil
        end
      end
    end

  end
end
