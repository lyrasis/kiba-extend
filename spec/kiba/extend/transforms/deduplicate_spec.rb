# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Deduplicate do
  let(:test_job_config){ { source: input, destination: output } }
  let(:test_job) { Kiba::Extend::Jobs::TestingJob.new(files: test_job_config, transformer: test_job_transforms) }
  let(:output){ [] }

  describe 'Fields' do
    context 'when casesensitive = true' do
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
      
      let(:test_job_transforms) do
        Kiba.job_segment do
          transform Deduplicate::Fields, source: :x, targets: %i[y z], multival: true, sep: ';'
        end
      end
      
      it 'removes value(s) of source field from target field(s)' do
        test_job
        expect(output).to eq(expected)
      end
    end

    context 'when casesensitive = false' do
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

      let(:test_job_transforms) do
        Kiba.job_segment do
          transform Deduplicate::Fields,
            source: :x,
            targets: %i[y z],
            multival: true,
            sep: ';',
            casesensitive: false
        end
      end
      it 'removes value(s) of source field from target field(s)' do
        test_job
        expect(output).to eq(expected)
      end
    end
  end

  describe 'FieldValues' do
    let(:input) do
      [
        {foo: '1;1;1;2;2;2', bar: 'a;A;b;b;b'},
        {foo: '', bar: 'q;r;r'},
        {foo: '1', bar: '2'},
        {foo: 1, bar: 2}
      ]
    end

    context 'when deleting deduplication field' do
      let(:test_job_transforms) do
        Kiba.job_segment do
          transform Deduplicate::FieldValues, fields: %i[foo bar], sep: ';'
        end
      end
      
      it 'deduplicates values in each field' do
        expected = [
          {foo: '1;2', bar: 'a;A;b'},
          {foo: '', bar: 'q;r'},
          {foo: '1', bar: '2'},
          {foo: '1', bar: '2'}
        ]
        test_job
        expect(output).to eq(expected)
      end
    end
  end

  describe 'Flag' do
    let(:input) do
      [
        {id: '1', x: 'a'},
        {id: '2', x: 'a'},
        {id: '1', x: 'b'},
        {id: '3', x: 'b'},
      ]
    end

    context 'when deleting deduplication field' do
      let(:test_job_transforms) do
        Kiba.job_segment do
          @deduper = {}
          transform Deduplicate::Flag, on_field: :id, in_field: :d, using: @deduper
        end
      end
      it 'deduplicates and removes field' do
        expected = [
          { id: '1', x: 'a', d: 'n' },
          { id: '2', x: 'a', d: 'n' },
          { id: '1', x: 'b', d: 'y' },
          { id: '3', x: 'b', d: 'n' }
        ]
        test_job
        expect(output).to eq(expected)
      end
    end
  end

  describe 'GroupedFieldValues' do
    rows = [
      %w[name role],
      ['Fred;Freda;Fred;James', 'author;photographer;editor;illustrator'],
      [';', ';'],
      %w[1 2]
    ]
    before do
      generate_csv(rows)
    end
    it 'removes duplicate values in one field, and removes corresponding fieldgroup values' do
      expected = [
        { name: 'Fred;Freda;James', role: 'author;photographer;illustrator' },
        { name: nil, role: nil },
        { name: '1', role: '2' }
      ]
      result = execute_job(filename: test_csv,
                           xform: Deduplicate::GroupedFieldValues,
                           xformopt: {
                             on_field: :name,
                             grouped_fields: %i[role],
                             sep: ';'
                           })
      expect(result).to eq(expected)
    end
  end

  describe 'Table' do
    let(:input) do
      [
        {foo: 'a', bar: 'b', baz: 'f', combined: 'a b'},
        {foo: 'c', bar: 'd', baz: 'g', combined: 'c d'},
        {foo: 'c', bar: 'e', baz: 'h', combined: 'c e'},
        {foo: 'c', bar: 'd', baz: 'i', combined: 'c d'},
      ]
    end

    context 'when deleting deduplication field' do
      let(:test_job_transforms) do
        Kiba.job_segment do
          transform Deduplicate::Table, field: :combined, delete_field: true
        end
      end
      it 'deduplicates and removes field' do
        expected = [
          {foo: 'a', bar: 'b', baz: 'f'},
          {foo: 'c', bar: 'd', baz: 'g'},
          {foo: 'c', bar: 'e', baz: 'h'}
        ]
        test_job
        expect(output).to eq(expected)
      end
    end

    context 'when keeping deduplication field' do
      let(:test_job_transforms) do
        Kiba.job_segment do
          transform Deduplicate::Table, field: :foo
        end
      end
      it 'deduplicates and retains all fields' do
        expected = [
          {foo: 'a', bar: 'b', baz: 'f', combined: 'a b'},
          {foo: 'c', bar: 'd', baz: 'g', combined: 'c d'}
        ]
        test_job
        expect(output).to eq(expected)
      end
    end
  end
end
