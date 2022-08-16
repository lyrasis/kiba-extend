# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Split::IntoMultipleColumns do
  subject(:xform){ Kiba::Extend::Transforms::Split::IntoMultipleColumns.new(**params) }
  let(:results){ rows.map{ |row| xform.process(row) } }
  
  context 'without max_segments param' do
    let(:row){ {summary: ''} }
    let(:params){ {field: :summary, sep: ':'} }
    
    it 'raises ArgumentError with expected message' do
      expect { xform.process(row) }.to raise_error(ArgumentError, 'missing keyword: :max_segments')
    end
  end

  context 'when longest split value = max_segments (2)' do
    let(:rows) do
      [
        {summary: 'a:b'},
        {summary: 'c'},
        {summary: ':d'}
      ]
    end
    let(:params){ {field: :summary, sep: ':', max_segments: 2} }

    it 'fills in blank field before @sep with empty string and empty extra columns to the right with nil' do
      expected = [
        { summary0: 'a', summary1: 'b' },
        { summary0: 'c', summary1: nil },
        { summary0: '', summary1: 'd' },
      ]
      expect(results).to eq(expected)
    end
  end

  context 'when longest split value (5) > max_segments (3)' do
    let(:rows) do
      [
        {summary: 'a:b:c:d:e'},
        {summary: 'f:g'},
        {summary: ''},
        {summary: nil}
      ]
    end
    let(:params){ {field: :summary, sep: ':', max_segments: 3} }
    
    it 'collapses on right' do
      expected = [
        { summary0: 'a', summary1: 'b', summary2: 'c:d:e' },
        { summary0: 'f', summary1: 'g', summary2: nil },
        { summary0: '', summary1: nil, summary2: nil },
        { summary0: nil, summary1: nil, summary2: nil }
      ]
      expect(results).to eq(expected)
    end
  end

  context 'when longest split value (5) > max_segments (3) and warnfield given' do
    let(:rows) do
      [
        {summary: 'a:b:c:d:e'},
        {summary: 'f:g'},
        {summary: ''},
        {summary: nil}
      ]
    end
    let(:params){ {field: :summary, sep: ':', max_segments: 3, warnfield: :warn} }
    
    it 'collapses on right and adds warning to warnfield' do
      expected = [
        { summary0: 'a', summary1: 'b', summary2: 'c:d:e',
         warn: 'max_segments less than total number of split segments' },
        { summary0: 'f', summary1: 'g', summary2: nil,
         warn: nil },
        { summary0: '', summary1: nil, summary2: nil, warn: nil },
        { summary0: nil, summary1: nil, summary2: nil, warn: nil }
      ]
      expect(results).to eq(expected)
    end
  end

  context 'when longest split value (5) > max_segments (3) and collapse_on :left' do
    let(:rows) do
      [
        {summary: 'a:b:c:d:e'},
        {summary: 'f:g'},
        {summary: ''},
        {summary: nil}
      ]
    end
    let(:params){ {field: :summary, sep: ':', max_segments: 3, collapse_on: :left} }
    
    it 'collapses on left' do
      expected = [
        { summary0: 'a:b:c', summary1: 'd', summary2: 'e' },
        { summary0: 'f', summary1: 'g', summary2: nil },
        { summary0: '', summary1: nil, summary2: nil },
        { summary0: nil, summary1: nil, summary2: nil }
      ]
      expect(results).to eq(expected)
    end
  end
end

