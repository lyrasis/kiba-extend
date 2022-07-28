# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Deduplicate::GroupedFieldValues do
  subject(:xform){ described_class.new(**params) }
  let(:params){ {on_field: onfield, grouped_fields: grouped, sep: sep} }
  let(:onfield){ :name }
  let(:grouped){ %i[work role] }
  let(:sep){ ';' }
  let(:result){ input.map{ |row| xform.process(row) } }

  let(:input) do
    [
        {name: 'Fred;Freda;Fred;James', work: 'Report;Book;Paper;Book', role: 'author;photographer;editor;illustrator'},
        {name: ';', work: ';', role: ';'},
        {name: 'Martha', work: 'Book', role: 'contributor'}
    ]
  end

    let(:expected) do
      [
        { name: 'Fred;Freda;James', work: 'Report;Book;Book', role: 'author;photographer;illustrator' },
        { name: nil, work: nil, role: nil },
        {name: 'Martha', work: 'Book', role: 'contributor'}
      ]
    end
    
    it 'deduplicates indicates non-duplicates with `n`' do
      expect(result).to eq(expected)
    end
end
