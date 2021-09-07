# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Reshape do
  let(:test_job_config){ { source: input, destination: output } }
  let(:test_job) { Kiba::Extend::Jobs::TestingJob.new(files: test_job_config, transformer: test_job_transforms) }
  let(:output){ [] }

  describe 'CollapseMultipleFieldsToOneTypedFieldPair' do
    context 'when source field may be multivalued' do
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

      let(:test_job_transforms) do
        Kiba.job_segment do
          transform Reshape::CollapseMultipleFieldsToOneTypedFieldPair,
            sourcefieldmap: {
              workphone: 'business',
              homephone: 'personal',
              mobilephone: 'mobile',
              otherphone: ''
            },
            datafield: :phoneNumber,
            typefield: :phoneType,
            sourcesep: '|',
            targetsep: ';'
        end
      end

      it 'reshapes the columns as specified after splitting source' do
        test_job
        expect(output).to eq(expected)
      end
    end
    
    context 'when source field is not multivalued' do
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

      let(:test_job_transforms) do
        Kiba.job_segment do
          transform Reshape::CollapseMultipleFieldsToOneTypedFieldPair,
            sourcefieldmap: {
              workphone: 'business',
              homephone: 'personal',
              mobilephone: 'mobile',
              otherphone: ''
            },
            datafield: :phoneNumber,
            typefield: :phoneType,
            targetsep: ';'
        end
      end

      
      it 'reshapes the columns as specified' do
        test_job
        expect(output).to eq(expected)
      end
    end
  end

  describe 'SimplePivot' do
    let(:input) do
      [
        {authority: 'person', norm: 'fred', term: 'Fred Q.', unrelated: 'foo'},
        {authority: 'org', norm: 'fred', term: 'Fred, Inc.', unrelated: 'bar'},
        {authority: 'location', norm: 'unknown', term: 'Unknown', unrelated: 'baz'},
        {authority: 'person', norm: 'unknown', term: 'Unknown', unrelated: 'fuz'},
        {authority: 'org', norm: 'unknown', term: 'Unknown', unrelated: 'aaa'},
        {authority: 'work', norm: 'book', term: 'Book', unrelated: 'eee'},
        {authority: 'location', norm: 'book', term: '', unrelated: 'zee'},
        {authority: '', norm: 'book', term: 'Book', unrelated: 'squeee'},        
        {authority: nil, norm: 'ghost', term: 'Ghost', unrelated: 'boo'},
        {authority: 'location', norm: '', term: 'Ghost', unrelated: 'zoo'},
        {authority: 'location', norm: 'ghost', term: nil, unrelated: 'poo'},
        {authority: 'org', norm: 'fred', term: 'Fred, Corp.', unrelated: 'bar'},
        {authority: 'issues', norm: nil, term: nil, unrelated: 'bah'},
      ]
    end

    let(:expected) do
      [
        {norm: 'fred', person: 'Fred Q.', org: 'Fred, Corp.', location: nil, work: nil, issues: nil},
        {norm: 'unknown', person: 'Unknown', org: 'Unknown', location: 'Unknown', work: nil, issues: nil},
        {norm: 'book', person: nil, org: nil, location: nil, work: 'Book', issues: nil}
      ]
    end

    let(:test_job_transforms) do
      Kiba.job_segment do
        transform Reshape::SimplePivot,
          field_to_columns: :authority,
          field_to_rows: :norm,
          field_to_col_vals: :term
      end
    end

    it 'reshapes the columns as specified after splitting source' do
      Helpers::ExampleFormatter.new(input, expected)
      test_job
      expect(output).to eq(expected)
    end
  end
end
