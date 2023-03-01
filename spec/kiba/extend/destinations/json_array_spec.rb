# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Destinations::JsonArray do
  before(:all){ @test_filename = 'output.json' }
  let(:testfile){ @test_filename }

  def run_job(input, output)
    job = Kiba.parse do
      source Kiba::Extend::Sources::Enumerable, input
      destination Kiba::Extend::Destinations::JsonArray, filename: output
    end

    Kiba.run(job)

    IO.read(output)
  end

  after(:each){ File.delete(@test_filename) if File.exist?(@test_filename) }

  context 'when simplest data ever' do
    let(:input) do
      [
        {a: 'and', b: 'bat'},
        {a: 'apple', b: 'board'}
      ]
    end
    let(:expected) do
      '[{"a":"and","b":"bat"},{"a":"apple","b":"board"}]'
    end
    it 'produces JSON as expected' do
      expect(run_job(input, testfile)).to eq(expected)
    end
  end

  context 'when ArchivesSpace template data' do
    let(:input) do
      [{
        Archival_Object__title: 'Image of Bob and Sue',
        Archival_Object__dates:[
          {
            Archival_Object__dates__begin: '1987',
            Archival_Object__dates__label: 'other',
            Archival_Object__dates__date_type: 'inclusive'
          },
          {
            Archival_Object__dates__end: '1989',
            Archival_Object__dates__label: 'other',
            Archival_Object__dates__date_type: 'inclusive'
          }
        ]
       },
       {
         Archival_Object__title: 'Audio recording of a horse',
         Archival_Object__subjects:[
           '/Subjects/1',
           '/Subjects/2'
         ]
       }]
    end

    let(:expected) do
      '[{"Archival_Object__title":"Image of Bob and Sue","Archival_Object__dates":[{"Archival_Object__dates__begin":"1987","Archival_Object__dates__label":"other","Archival_Object__dates__date_type":"inclusive"},{"Archival_Object__dates__end":"1989","Archival_Object__dates__label":"other","Archival_Object__dates__date_type":"inclusive"}]},{"Archival_Object__title":"Audio recording of a horse","Archival_Object__subjects":["/Subjects/1","/Subjects/2"]}]'
    end
    it 'produces JSON as expected' do
      expect(run_job(input, testfile)).to eq(expected)
    end
  end
end
