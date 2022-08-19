# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Replace::FieldValueWithStaticMapping do
  subject(:xform){ described_class.new(**params) }

  describe '.new' do
    context 'with multival' do
      let(:params){ {source: :color, target: :fullcol, mapping: {}, multival: true} }

      it 'warns' do
        allow_any_instance_of(described_class).to receive(:warn).with(described_class.multival_warning)
        expect(xform.instance_variable_get(:@multival)).to be_falsey
      end
    end

    context 'with delim and sep' do
      let(:params){ {source: :color, target: :fullcol, mapping: {}, sep: ';', delim: '|'} }

      it 'warns' do
        allow_any_instance_of(described_class).to receive(:warn).with(described_class.delim_and_sep_warning)
        inst = xform
        expect(inst.instance_variable_get(:@delim)).to eq('|')
        expect(inst.instance_variable_get(:@multival)).to be true
      end
    end

    context 'with sep' do
      let(:params){ {source: :color, target: :fullcol, mapping: {}, sep: ';'} }

      it 'warns' do
        allow_any_instance_of(described_class).to receive(:warn).with(described_class.sep_warning)
        inst = xform
        expect(inst.instance_variable_get(:@delim)).to eq(';')
        expect(inst.instance_variable_get(:@multival)).to be true
      end
    end
  end
  
  describe '#process' do
    let(:mapping) do
      {
        'cb' => 'coral blue',
        'rp' => 'royal purple',
        'p' => 'pied',
        'pl' => 'pearl gray',
        nil => 'undetermined'
      }
    end
    let(:rows) do
      [
        {name: 'Lazarus', color: 'cb'},
        {name: 'Inkpot', color: 'rp'},
        {name: 'Zipper', color: 'rp|p'},
        {name: 'Divebomber|Earlybird', color: 'pl|pl'},
        {name: 'Vern', color: 'v'},
        {name: 'Clover|Hops', color: 'rp|c'},
        {name: 'New', color: nil},
        {name: 'Old', color: ''},
        {name: 'New|Hunter', color: '|pl'}
      ]
    end
    let(:results){ rows.map{ |row| xform.process(row) } }

    context 'with defaults' do
      let(:params){ {source: :color, mapping: mapping} }
      
      it 'transforms as expected' do
        expected = [
          {name: 'Lazarus', color: 'coral blue'},
          {name: 'Inkpot', color: 'royal purple'},
          {name: 'Zipper', color: 'rp|p'},
          {name: 'Divebomber|Earlybird', color: 'pl|pl'},
          {name: 'Vern', color: 'v'},
          {name: 'Clover|Hops', color: 'rp|c'},
          {name: 'New', color: 'undetermined'},
          {name: 'Old', color: ''},
          {name: 'New|Hunter', color: '|pl'}
        ]
        expect(results).to eq(expected)
      end
    end

    context 'with target' do
      let(:rows){ [{name: 'Lazarus', color: 'cb'}] }

      context 'when delete_source true' do
        let(:params){ {source: :color, target: :fullcol, mapping: mapping} }
        
        it 'transforms as expected' do
          expected = [
            {:name=>"Lazarus", :fullcol=>"coral blue"}
          ]
          expect(results).to eq(expected)
        end
      end

      context 'when delete_source false' do
        let(:params){ {source: :color, target: :fullcol, mapping: mapping, delete_source: false} }
        
        it 'transforms as expected' do
          expected = [
            {:name=>"Lazarus", :color=>"cb", :fullcol=>"coral blue"}
          ]
          expect(results).to eq(expected)
        end
      end
    end
    
    context 'with delim' do
      let(:params){ {source: :color, mapping: mapping, delim: '|'} }
      
      it 'transforms as expected' do
        expected = [
          {name: 'Lazarus', color: 'coral blue'},
          {name: 'Inkpot', color: 'royal purple'},
          {name: 'Zipper', color: 'royal purple|pied'},
          {name: 'Divebomber|Earlybird', color: 'pearl gray|pearl gray'},
          {name: 'Vern', color: 'v'},
          {name: 'Clover|Hops', color: 'royal purple|c'},
          {name: 'New', color: 'undetermined'},
          {name: 'Old', color: ''},
          {name: 'New|Hunter', color: '|pearl gray'}
        ]
        expect(results).to eq(expected)
      end
    end

    context 'When mapping does not contain matching key' do
      let(:rows) do
        [
          {name: 'Vern', color: 'v'},
          {name: 'Clover|Hops', color: 'rp|c'},
          {name: 'New', color: nil},
          {name: 'Old', color: ''},
          {name: 'New|Hunter', color: '|pl'}
        ]
      end

      context 'and :fallback_val = :nil' do
        let(:params){ {source: :color, mapping: mapping, delim: '|', fallback_val: :nil} }
        let(:expected) do
          [
            {name: 'Vern', color: nil},
            {name: 'Clover|Hops', color: 'royal purple|'},
            {name: 'New', color: 'undetermined'},
            {name: 'Old', color: nil},
            {name: 'New|Hunter', color: '|pearl gray'}
          ]
        end

        it 'sends nil through to new column' do
          expect(results).to eq(expected)
        end
      end

      context 'and :fallback_val = `nope`' do
        let(:params){ {source: :color, mapping: mapping, delim: '|', fallback_val: 'nope'} }
        let(:expected) do
          [
            {name: 'Vern', color: 'nope'},
            {name: 'Clover|Hops', color: 'royal purple|nope'},
            {name: 'New', color: 'undetermined'},
            {name: 'Old', color: 'nope'},
            {name: 'New|Hunter', color: 'nope|pearl gray'}
          ]
        end

        it 'sends nil through to new column' do
          expect(results).to eq(expected)
        end
      end
    end
  end
end
