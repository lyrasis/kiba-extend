# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Merge do
  let(:accumulator){ [] }
  let(:test_job){ Helpers::TestJob.new(input: input, accumulator: accumulator, transforms: transforms) }
  let(:result){ test_job.accumulator }

  describe 'ConstantValue' do
    before do
      generate_csv(rows)
    end
    after do
      File.delete(test_csv) if File.exist?(test_csv)
    end

    let(:rows) do
      [
        %w[id name sex source],
        [1, 'Weddy', 'm', 'adopted'],
        [2, 'Kernel', 'f', 'adopted']
      ]
    end

    it 'merges specified constant data values into row' do
      expected = [
        { id: '1', name: 'Weddy', sex: 'm', source: 'adopted', species: 'guinea fowl' },
        { id: '2', name: 'Kernel', sex: 'f', source: 'adopted', species: 'guinea fowl' }
      ]
      result = execute_job(filename: test_csv,
                           xform: Merge::ConstantValue,
                           xformopt: { target: :species, value: 'guinea fowl' })
      expect(result).to eq(expected)
    end
  end

  describe 'ConstantValueConditional' do
    before do
      generate_csv(rows)
    end
    after do
      File.delete(test_csv) if File.exist?(test_csv)
    end

    let(:opt) do
      {
        fieldmap: { reason: 'gift' },
        conditions: {
          include: {
            field_equal: { fieldsets: [
              {
                matches: [
                  ['row::note', 'revalue::[Gg]ift'],
                  ['row::note', 'revalue::[Dd]onation']
                ]
              }
            ] }
          }
        }
      }
    end
    context 'when row meets criteria' do
      let(:rows) do
        [
          %w[id reason note],
          [1, nil, 'Gift'],
          [2, nil, 'donation']
        ]
      end

      it 'merges constant data values into specified field' do
        expected = [
          { id: '1', reason: 'gift', note: 'Gift' },
          { id: '2', reason: 'gift', note: 'donation' }
        ]
        result = execute_job(filename: test_csv,
                             xform: Merge::ConstantValueConditional,
                             xformopt: opt)
        expect(result).to eq(expected)
      end

      context 'when target field has a pre-existing value' do
        let(:rows) do
          [
            %w[id reason note],
            [1, 'donation', 'Gift']
          ]
        end
        it 'that value is overwritten by the specified constant value' do
          expected = [
            { id: '1', reason: 'gift', note: 'Gift' }
          ]
          result = execute_job(filename: test_csv,
                               xform: Merge::ConstantValueConditional,
                               xformopt: opt)
          expect(result).to eq(expected)
        end
      end
    end

    context 'when row does not meet criteria' do
      context 'and target field already exists in row' do
        let(:rows) do
          [
            %w[id reason note],
            [2, 'misc', 'Something else']
          ]
        end
        it 'target field value stays the same' do
          expected = [
            { id: '2', reason: 'misc', note: 'Something else' }
          ]
          result = execute_job(filename: test_csv,
                               xform: Merge::ConstantValueConditional,
                               xformopt: opt)
          expect(result).to eq(expected)
        end
      end

      context 'and target field does not exist in row' do
        let(:rows) do
          [
            %w[id note],
            [2, 'Something else']
          ]
        end
        it 'target field is added to row, with nil value' do
          expected = [
            { id: '2', reason: nil, note: 'Something else' }
          ]
          result = execute_job(filename: test_csv,
                               xform: Merge::ConstantValueConditional,
                               xformopt: opt)
          expect(result).to eq(expected)
        end
      end
    end
  end

  describe 'MultivalueConstant' do
    let(:input) do
      [
        {name: 'Weddy'},
        {name: 'NULL'},
        {name: ''},
        {name: nil},
        {name: 'Earlybird;Divebomber'},
        {name: ';Niblet'},
        {name: 'Hunter;'},
        {name: 'NULL;Earhart'}
      ]
    end

    let(:transforms) do
      Kiba.job_segment do
        transform Merge::MultivalueConstant, on_field: :name, target: :species, value: 'guinea fowl', sep: ';', placeholder: 'NULL'
      end
    end
    
    let(:expected) do
      [
        { name: 'Weddy', species: 'guinea fowl' },
        { name: 'NULL', species: 'NULL' },
        { name: '', species: 'NULL' },
        { name: nil, species: 'NULL' },
        { name: 'Earlybird;Divebomber', species: 'guinea fowl;guinea fowl' },
        { name: ';Niblet', species: 'NULL;guinea fowl' },
        { name: 'Hunter;', species: 'guinea fowl;NULL' },
        { name: 'NULL;Earhart', species: 'NULL;guinea fowl' }
      ]
    end
    
    it 'adds specified value to new field once per value in specified field' do
      expect(result).to eq(expected)
    end
  end

  describe 'MultiRowLookup' do
    before do
      generate_csv(rows)
    end
    after do
      File.delete(test_csv) if File.exist?(test_csv)
    end

    context 'when multikey = false (default)' do
      let(:rows) do
        [
          %w[id name sex source],
          [1, 'Weddy', 'm', 'adopted'],
          [2, 'Kernel', 'f', 'adopted'],
          [3, 'Boris', 'm', 'adopted'],
          [4, 'Earlybird', 'f', 'hatched'],
          [5, 'Lazarus', 'm', 'adopted'],
          [nil, 'Null', '', '']
        ]
      end
      lookup_rows = [
        %w[id date treatment],
        [1, '2019-07-21', 'hatch'],
        [2, '2019-08-01', 'hatch'],
        [1, '2019-09-15', 'adopted'],
        [2, '2019-09-15', 'adopted'],
        [1, '2020-04-15', 'deworm'],
        [2, '2020-04-15', 'deworm'],
        [4, '', '']
      ]
      let(:lookup) { Lookup.csv_to_multi_hash(file: lookup_csv, csvopt: CSVOPT, keycolumn: :id) }
      let(:xformopt) do
        {
          fieldmap: {
            date: :date,
            event: :treatment
          },
          lookup: lookup,
          keycolumn: :id
        }
      end
      before do
        generate_lookup_csv(lookup_rows)
      end

      it 'merges values from specified fields into multivalued fields' do
        expected = [
          { id: '1', name: 'Weddy', sex: 'm', source: 'adopted',
           date: '2019-07-21;2019-09-15;2020-04-15',
           event: 'hatch;adopted;deworm' },
          { id: '2', name: 'Kernel', sex: 'f', source: 'adopted',
           date: '2019-08-01;2019-09-15;2020-04-15',
           event: 'hatch;adopted;deworm' },
          { id: '3', name: 'Boris', sex: 'm', source: 'adopted',
           date: nil,
           event: nil },
          { id: '4', name: 'Earlybird', sex: 'f', source: 'hatched',
           date: nil,
           event: nil },
          { id: '5', name: 'Lazarus', sex: 'm', source: 'adopted',
           date: nil,
           event: nil },
          { id: nil, name: 'Null', sex: '', source: '',
           date: nil,
           event: nil }
        ]
        result = execute_job(filename: test_csv, xform: Merge::MultiRowLookup, xformopt: xformopt)
        expect(result).to eq(expected)
      end

      it 'merges specified constant values into specified fields for each row merged' do
        opt = xformopt.merge({ constantmap: { by: 'kms', loc: 'The Thicket' } })
        expected = [
          { id: '1', name: 'Weddy', sex: 'm', source: 'adopted',
           date: '2019-07-21;2019-09-15;2020-04-15',
           event: 'hatch;adopted;deworm',
           by: 'kms;kms;kms',
           loc: 'The Thicket;The Thicket;The Thicket' },
          { id: '2', name: 'Kernel', sex: 'f', source: 'adopted',
           date: '2019-08-01;2019-09-15;2020-04-15',
           event: 'hatch;adopted;deworm',
           by: 'kms;kms;kms',
           loc: 'The Thicket;The Thicket;The Thicket' },
          { id: '3', name: 'Boris', sex: 'm', source: 'adopted',
           date: nil,
           event: nil,
           by: nil, loc: nil },
          { id: '4', name: 'Earlybird', sex: 'f', source: 'hatched',
           date: nil,
           event: nil,
           by: nil, loc: nil },
          { id: '5', name: 'Lazarus', sex: 'm', source: 'adopted',
           date: nil,
           event: nil,
           by: nil, loc: nil },
          { id: nil, name: 'Null', sex: '', source: '',
           date: nil,
           event: nil,
           by: nil, loc: nil }
        ]
        result = execute_job(filename: test_csv, xform: Merge::MultiRowLookup, xformopt: opt)
        expect(result).to eq(expected)
      end

      after do
        File.delete(lookup_csv) if File.exist?(lookup_csv)
      end
    end

    context 'when multikey = true' do
      let(:rows) do
        [
          ['single'],
          ['a|b|c'],
          ['d'],
          ['e|f|g'],
          ['h'],
          [nil]
        ]
      end
      lookup_rows = [
        %w[single double triple],
        %w[a aa aaa],
        %w[b bb bbb],
        ['b', 'beebee', ''],
        %w[c cc ccc],
        %w[d dd ddd],
        %w[e ee eee],
        ['g', '', 'ggg']
      ]
      let(:lookup) { Lookup.csv_to_multi_hash(file: lookup_csv, csvopt: CSVOPT, keycolumn: :single) }
      let(:xformopt) do
        {
          fieldmap: {
            doubles: :double,
            triples: :triple
          },
          lookup: lookup,
          keycolumn: :single,
          multikey: true,
          delim: '|'
        }
      end
      before do
        generate_lookup_csv(lookup_rows)
      end

      it 'merges values from specified fields into multivalued fields' do
        expected = [
          { single: 'a|b|c', doubles: 'aa|bb|beebee|cc', triples: 'aaa|bbb||ccc' },
          { single: 'd', doubles: 'dd', triples: 'ddd' },
          { single: 'e|f|g', doubles: 'ee|', triples: 'eee|ggg' },
          { single: 'h', doubles: nil, triples: nil },
          { single: nil, doubles: nil, triples: nil }
        ]
        result = execute_job(filename: test_csv, xform: Merge::MultiRowLookup, xformopt: xformopt)
        expect(result).to eq(expected)
      end

      it 'merges specified constant values into specified fields for each row merged' do
        opt = xformopt.merge({ constantmap: { quad: 4, pent: 5 } })
        expected = [
          { single: 'a|b|c', doubles: 'aa|bb|beebee|cc', triples: 'aaa|bbb||ccc', quad: '4|4|4|4', pent: '5|5|5|5' },
          { single: 'd', doubles: 'dd', triples: 'ddd', quad: '4', pent: '5' },
          { single: 'e|f|g', doubles: 'ee|', triples: 'eee|ggg', quad: '4|4', pent: '5|5' },
          { single: 'h', doubles: nil, triples: nil, quad: nil, pent: nil },
          { single: nil, doubles: nil, triples: nil, quad: nil, pent: nil }
        ]
        result = execute_job(filename: test_csv, xform: Merge::MultiRowLookup, xformopt: opt)
        expect(result).to eq(expected)
      end

      after do
        File.delete(lookup_csv) if File.exist?(lookup_csv)
      end
    end
  end
end
