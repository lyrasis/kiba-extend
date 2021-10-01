# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Destinations::JsonArray do
  TEST_FILENAME = 'output.json'

  def run_job(input)
    job = Kiba.parse do
      source Kiba::Common::Sources::Enumerable, input
      destination Kiba::Extend::Destinations::JsonArray, filename: TEST_FILENAME
    end

    Kiba.run(job)

    IO.read(TEST_FILENAME)
  end

  after(:each){ File.delete(TEST_FILENAME) if File.exist?(TEST_FILENAME) }

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
      expect(run_job(input)).to eq(expected)
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
      expect(run_job(input)).to eq(expected)
    end
  end
end

