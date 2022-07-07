# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::CombineValues::AcrossFieldGroup do
  subject(:xform){ described_class.new(**params) }
  let(:params){ {fieldmap: fieldmap, sep: sep }}
  let(:sep){ '|' }
  let(:result){ input.map{ |row| xform.process(row) } }

  let(:input) do
    [
      {person: '', statusa: '', date: '', personb: '', statusb: '', date2: '', personc: '', statusc: '', date3: ''},
      {person: 'jim', statusa: 'approved', date: '2020',
       personb: 'bill', statusb: 'requested', date2: '2019',
       personc: 'terri', statusc: 'authorized', date3: '2018'},
      {person: 'jim|mavis', statusa: 'approved|', date: '2020|2021',
       personb: 'bill', statusb: 'requested', date2: '2019',
       personc: 'terri', statusc: 'authorized', date3: '2018'},
      {person: nil, statusa: 'acknowledged', date: '2020',
       personb: 'jill', statusb: 'requested', date2: nil,
       personc: 'bill', statusc: 'followup', date3: '2021'},
      {person: '%NULLVALUE%|%NULLVALUE%', statusa: 'acknowledged|approved', date: '2020|%NULLVALUE%',
       personb: 'jill', statusb: 'requested', date2: nil,
       personc: 'bill', statusc: 'followup', date3: '2019'}
    ]
  end

  context 'with uneven fieldmap' do
    let(:expected) do
      [
        {person: '||',
         status: '|',
         statusdate: '',
         statusc: '', date2: '', date3: ''},
        {person: 'jim|bill|terri',
         status: 'approved|requested',
         statusdate: '2020',
        statusc: 'authorized', date2: '2019', date3: '2018'},
        {person: 'jim|mavis|bill|terri',
         status: 'approved||requested',
         statusdate: '2020|2021',
        statusc: 'authorized', date2: '2019', date3: '2018'},
        {person: '|jill|bill',
         status: 'acknowledged|requested',
         statusdate: '2020',
        statusc: 'followup', date2: nil, date3: '2021'},
        {person: '%NULLVALUE%|%NULLVALUE%|jill|bill',
         status: 'acknowledged|approved|requested',
         statusdate: '2020|%NULLVALUE%',
        statusc: 'followup', date2: nil, date3: '2019'}
      ]
    end
    
    let(:fieldmap) do
      {
        person: %i[person personb personc],
        status: %i[statusa statusb],
        statusdate: %i[date]
      }
    end
    it 'concatenates specified field values' do
      expect(result).to eq(expected)
    end
  end

  context 'with even fieldmap' do
    let(:expected) do
      [
        {person: '||',
         status: '||',
         statusdate: '||'},
        {person: 'jim|bill|terri',
         status: 'authorized|approved|requested',
         statusdate: '2020|2019|2018' },
        {person: 'jim|mavis|bill|terri',
         status: 'authorized|approved||requested',
         statusdate: '2020|2021|2019|2018' },
        {person: '|jill|bill',
         status: 'followup|acknowledged|requested',
         statusdate: '2020||2021' },
        {person: '%NULLVALUE%|%NULLVALUE%|jill|bill',
         status: 'followup|acknowledged|approved|requested',
         statusdate: '2020|%NULLVALUE%||2019' }
      ]
    end
    let(:fieldmap) do
      {
        person: %i[person personb personc],
        status: %i[statusc statusa statusb],
        statusdate: %i[date date2 date3]
      }
    end
    it 'concatenates specified field values' do
      expect(result).to eq(expected)
    end
  end
end

