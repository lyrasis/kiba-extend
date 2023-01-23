# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Clean do
  let(:accumulator){ [] }
  let(:test_job){ Helpers::TestJob.new(input: input, accumulator: accumulator, transforms: transforms) }
  let(:result){ test_job.accumulator }

  describe 'AlphabetizeFieldValues' do
    let(:input) do
      [
        { type: 'Person;unmapped;Organization'},
        { type: ';'},
        { type: nil},
        { type: ''},
        { type: 'Person;notmapped'},
        { type: '%NULLVALUE%;apple'},
        { type: 'oatmeal;%NULLVALUE%'}
      ]
    end

    context 'when when usenull = false' do
      context 'when direction = :asc' do
        let(:transforms) do
          Kiba.job_segment do
            transform Clean::AlphabetizeFieldValues, fields: %i[type], delim: ';', usenull: false,
              direction: :asc
          end
        end

        it 'sorts as expected' do
          expected = [
            { type: 'Organization;Person;unmapped'},
            { type: ';'},
            { type: nil},
            { type: ''},
            { type: 'notmapped;Person'},
            { type: 'apple;%NULLVALUE%'},
            { type: '%NULLVALUE%;oatmeal'}
          ]
          expect(result).to eq(expected)
        end

        context 'when direction = :desc' do
          let(:transforms) do
            Kiba.job_segment do
              transform Clean::AlphabetizeFieldValues, fields: %i[type], delim: ';', usenull: false,
                direction: :desc
            end
          end

          it 'sorts as expected' do
            expected = [
              { type: 'unmapped;Person;Organization'},
              { type: ';'},
              { type: nil},
              { type: ''},
              { type: 'Person;notmapped'},
              { type: '%NULLVALUE%;apple'},
              { type: 'oatmeal;%NULLVALUE%'}
            ]
            expect(result).to eq(expected)
          end
        end
      end
    end

    context 'when usenull = true' do
      context 'when direction = :asc' do
        let(:transforms) do
          Kiba.job_segment do
            transform Clean::AlphabetizeFieldValues, fields: %i[type], delim: ';', usenull: true,
              direction: :asc
          end
        end

        it 'sorts as expected' do
          expected = [
            { type: 'Organization;Person;unmapped'},
            { type: ';'},
            { type: nil},
            { type: ''},
            { type: 'notmapped;Person'},
            { type: 'apple;%NULLVALUE%'},
            { type: 'oatmeal;%NULLVALUE%'}
          ]
          expect(result).to eq(expected)
        end
      end


      context 'when direction = :desc' do
        let(:transforms) do
          Kiba.job_segment do
            transform Clean::AlphabetizeFieldValues, fields: %i[type], delim: ';', usenull: true,
              direction: :desc
          end
        end

        it 'sorts as expected' do
          expected = [
            { type: 'unmapped;Person;Organization'},
            { type: ';'},
            { type: nil},
            { type: ''},
            { type: 'Person;notmapped'},
            { type: '%NULLVALUE%;apple'},
            { type: '%NULLVALUE%;oatmeal'}
          ]
          expect(result).to eq(expected)
        end
      end
    end
  end

  describe 'ClearFields' do
    rows = [
      %w[id type],
      ['1', 'Person;unmapped;Organization'],
      ['2', ';'],
      ['3', nil],
      ['4', ''],
      ['5', 'Person;notmapped']
    ]

    before { generate_csv(rows) }
    context 'without additional arguments' do
      it 'sets the value of the field in all rows to nil' do
        result = execute_job(filename: test_csv,
                             xform: Clean::ClearFields,
                             xformopt: { fields: %i[type] })
        expect(result.map { |e| e[1] }.uniq[0]).to be_nil
      end
    end
    context 'with if_equals argument' do
      it 'sets the value of the field to nil if it matches `if_equals`' do
        result = execute_job(filename: test_csv,
                             xform: Clean::ClearFields,
                             xformopt: { fields: %i[type], if_equals: ';' })
        expect(result.map { |e| e[1] }.uniq[0]).to be_nil
      end
    end
  end

  describe 'DowncaseFieldValues' do
    after { File.delete(test_csv) if File.exist?(test_csv) }

    it 'downcases value(s) of specified field(s)' do
      rows = [
        %w[val x],
        %w[Aaa 123],
        ['Bbb', '']
      ]
      generate_csv(rows)
      result = execute_job(filename: test_csv,
                           xform: Clean::DowncaseFieldValues,
                           xformopt: {
                             fields: %i[val x]
                           })
      expected = [
        { val: 'aaa', x: '123' },
        { val: 'bbb', x: '' }
      ]
      expect(result).to eq(expected)
    end
  end

  describe 'EmptyFieldGroups' do
    let(:rows) do
      [
        %w[id a1 a2 b1 b2 b3],
        ['4', 'not;', nil, ';empty', ';empty', ';empty'],
        ['1', 'not;empty', 'not;empty', 'not;empty', 'not;empty', 'not;empty'],
        ['2', 'not;', 'not;', ';empty', 'not;empty', ';empty'],
        ['3', ';', ';', ';empty', ';empty', ';empty'],
        ['5', '%NULLVALUE%;%NULLVALUE%', '%NULLVALUE%;%NULLVALUE%', 'not;empty', '%NULLVALUE%;empty',
         'empty;%NULLVALUE%'],
        ['6', ';', ';', '%NULLVALUE%;empty', '%NULLVALUE%;empty', '%NULLVALUE%;empty']
      ]
    end
    after { File.delete(test_csv) if File.exist?(test_csv) }

    context 'When use_nullvalue = false (the default)' do
      it 'Removes field groups where all fields in group are empty' do
        generate_csv(rows)
        result = execute_job(filename: test_csv,
                             xform: Clean::EmptyFieldGroups,
                             xformopt: {
                               groups: [
                                 %i[a1 a2],
                                 %i[b1 b2 b3]
                               ],
                               sep: ';',
                               use_nullvalue: false
                             })
        expected = [
          { id: '4',
           a1: 'not',
           a2: nil,
           b1: 'empty',
           b2: 'empty',
           b3: 'empty' },
          { id: '1',
           a1: 'not;empty',
           a2: 'not;empty',
           b1: 'not;empty',
           b2: 'not;empty',
           b3: 'not;empty' },
          { id: '2',
           a1: 'not',
           a2: 'not',
           b1: ';empty',
           b2: 'not;empty',
           b3: ';empty' },
          { id: '3',
           a1: nil,
           a2: nil,
           b1: 'empty',
           b2: 'empty',
           b3: 'empty' },
          { id: '5',
           a1: '%NULLVALUE%;%NULLVALUE%',
           a2: '%NULLVALUE%;%NULLVALUE%',
           b1: 'not;empty',
           b2: '%NULLVALUE%;empty',
           b3: 'empty;%NULLVALUE%' },
          { id: '6',
           a1: nil,
           a2: nil,
           b1: '%NULLVALUE%;empty',
           b2: '%NULLVALUE%;empty',
           b3: '%NULLVALUE%;empty' }
        ]
        expect(result).to eq(expected)
      end
    end
    context 'When use_nullvalue = true' do
      it 'Removes field groups where all fields in group are empty' do
        generate_csv(rows)
        result = execute_job(filename: test_csv,
                             xform: Clean::EmptyFieldGroups,
                             xformopt: {
                               groups: [
                                 %i[a1 a2],
                                 %i[b1 b2 b3]
                               ],
                               sep: ';',
                               use_nullvalue: true
                             })
        expected = [
          { id: '4',
           a1: 'not',
           a2: nil,
           b1: 'empty',
           b2: 'empty',
           b3: 'empty' },
          { id: '1',
           a1: 'not;empty',
           a2: 'not;empty',
           b1: 'not;empty',
           b2: 'not;empty',
           b3: 'not;empty' },
          { id: '2',
           a1: 'not',
           a2: 'not',
           b1: '%NULLVALUE%;empty',
           b2: 'not;empty',
           b3: '%NULLVALUE%;empty' },
          { id: '3',
           a1: nil,
           a2: nil,
           b1: 'empty',
           b2: 'empty',
           b3: 'empty' },
          { id: '5',
           a1: nil,
           a2: nil,
           b1: 'not;empty',
           b2: '%NULLVALUE%;empty',
           b3: 'empty;%NULLVALUE%' },
          { id: '6',
           a1: nil,
           a2: nil,
           b1: 'empty',
           b2: 'empty',
           b3: 'empty' }
        ]
        expect(result).to eq(expected)
      end
    end
  end
end
