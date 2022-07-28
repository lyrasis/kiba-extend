# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Deduplicate::Fields do
  subject(:xform) do
    described_class.new(
      source: source,
      targets: targets,
      multival: multival,
      sep: sep,
      casesensitive: casesensitive)
  end
  let(:source){ :x }
  let(:targets){ %i[y z] }
  let(:multival){ true }
  let(:sep){ ';' }
  let(:result){ input.map{ |row| xform.process(row) } }
  
  context 'when casesensitive = true' do
  let(:casesensitive){ true }
    let(:input) do
      [
        {x: 'a', y: 'a', z: 'b'},
        {x: 'a', y: 'a', z: 'a'},
        {x: 'a', y: 'b;a', z: 'a;c'},
        {x: 'a;b', y: 'b;a', z: 'a;c'},
        {x: 'a', y: 'aa', z: 'bat'},
        {x: nil, y: 'a', z: nil},
        {x: '', y: ';a', z: 'b;'},
        {x: 'a', y: nil, z: nil},
        {x: 'a', y: 'A', z: 'a'},
      ]
    end

    let(:expected) do
      [
        { x: 'a', y: nil, z: 'b' },
        { x: 'a', y: nil, z: nil },
        { x: 'a', y: 'b', z: 'c' },
        { x: 'a;b', y: nil, z: 'c' },
        { x: 'a', y: 'aa', z: 'bat' },
        { x: nil, y: 'a', z: nil },
        { x: '', y: 'a', z: 'b' },
        { x: 'a', y: nil, z: nil },
        { x: 'a', y: 'A', z: nil }
      ]
    end
    
    it 'removes value(s) of source field from target field(s)' do
      expect(result).to eq(expected)
    end
  end

  context 'when casesensitive = false' do
    let(:casesensitive){ false }
    let(:input) do
      [
        { x: 'a', y: 'A', z: 'a' },
        { x: 'a', y: 'a', z: 'B' },
      ]
    end
    
    let(:expected) do
      [
        { x: 'a', y: nil, z: nil },
        { x: 'a', y: nil, z: 'B' }
      ]
    end

    it 'removes value(s) of source field from target field(s)' do
      expect(result).to eq(expected)
    end
  end
end
