# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Reshape::SimplePivot do
  subject(:xform){ described_class.new(**params) }
  let(:params) do
    {
      field_to_columns: field_to_columns,
      field_to_rows: field_to_rows,
      field_to_col_vals: field_to_col_vals
    }
  end

  let(:field_to_columns){ :authority }
  let(:field_to_rows){ :norm }
  let(:field_to_col_vals){ :term }
  
  let(:result) do
    Kiba::StreamingRunner.transform_stream(input, xform)
      .map{ |row| row }
  end

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

  it 'pivots as expected' do
    expect(result).to eq(expected)
  end
end
