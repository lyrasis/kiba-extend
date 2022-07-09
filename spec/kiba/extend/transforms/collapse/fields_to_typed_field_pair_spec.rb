# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Collapse::FieldsToTypedFieldPair do
  subject(:xform){ described_class.new(**params) }
  let(:sourcefieldmap) do
    {
      workphone: 'business',
      homephone: 'personal',
      mobilephone: 'mobile',
      otherphone: ''
    }
  end
  let(:datafield){ :phoneNumber }
  let(:typefield){ :phoneType }
  let(:targetsep){ ';' }
  
  let(:result){ input.map{ |row| xform.process(row) } }

  context 'when source field may be multivalued' do
    let(:params) do
      {
        sourcefieldmap: sourcefieldmap,
        datafield: datafield,
        typefield: typefield,
        sourcesep: sourcesep,
        targetsep: targetsep
      }
    end
    let(:sourcesep){ '|' }
    
    let(:input) do
      [{
        homephone: '2',
        workphone: '1',
        mobilephone: '3|4',
        otherphone: '5',
        unrelated: 'foo'
       }]
    end
    let(:expected) do
      [{
        phoneNumber: '1;2;3;4;5',
        phoneType: 'business;personal;mobile;mobile;',
        unrelated: 'foo'
       }]
    end

    it 'reshapes the columns as specified after splitting source' do
      expect(result).to eq(expected)
    end
  end

  context 'when source field is not multivalued' do
    let(:params) do
      {
        sourcefieldmap: sourcefieldmap,
        datafield: datafield,
        typefield: typefield,
        targetsep: targetsep
      }
    end

    let(:input) do
      [{
        homephone: '123',
        workphone: '234',
        mobilephone: '345|456',
        otherphone: '567',
        unrelated: 'foo'
       },
       {
         homephone: '123',
         workphone: '234',
         mobilephone: '345 456',
         otherphone: '567',
         unrelated: 'bar'
       }]
    end

    let(:expected) do
      [
        { phoneNumber: '234;123;345|456;567', phoneType: 'business;personal;mobile;', unrelated: 'foo'},
        { phoneNumber: '234;123;345 456;567', phoneType: 'business;personal;mobile;', unrelated: 'bar'},
      ]
    end

    it 'reshapes the columns as specified' do
      expect(result).to eq(expected)
    end
  end
end
