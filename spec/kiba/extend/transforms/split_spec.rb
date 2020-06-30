require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Split do
  describe 'IntoMultipleColumns' do
    test_csv = 'tmp/test.csv'
    context 'when sep = :' do
      context 'and value = summary: 8x10; 5x7' do
      rows = [
        ['id', 'summary'],
        [1, 'overall: 8x10; 5x7']
      ]
      before do
        generate_csv(test_csv, rows)
      end
      it 'splits into two columns' do
        expected = [
          {id: '1', summary0: 'overall', summary1: '8x10; 5x7'}
        ]
        result = execute_job(filename: test_csv,
                             xform: Split::IntoMultipleColumns,
                             xformopt: {
                               field: :summary,
                               sep: ':'
                             })
        expect(result).to eq(expected)
      end
      end

      context 'and value = : 8x10; 5x7' do
        rows = [
          ['id', 'summary'],
          [1, ': 8x10; 5x7']
        ]
        before do
          generate_csv(test_csv, rows)
        end
        it 'splits into two columns' do
          expected = [
            {id: '1', summary0: nil, summary1: '8x10; 5x7'}
          ]
          result = execute_job(filename: test_csv,
                               xform: Split::IntoMultipleColumns,
                               xformopt: {
                                 field: :summary,
                                 sep: ':'
                               })
          expect(result).to eq(expected)
        end
      end

      context 'and max_segments = 2' do
        context 'and value = overall: 8x10 ; base: 7x7' do
          context 'and collapse_on = :right' do
          context 'and no warnfield given' do
            rows = [
              ['id', 'summary'],
              [1, 'overall: 8x10; base: 7x7']
            ]
            @info = []
            before do
              generate_csv(test_csv, rows)
            end
            it 'splits into two columns' do
              expected = [
                {id: '1', summary0: 'overall', summary1: '8x10; base: 7x7'}
              ]
              result = execute_job(filename: test_csv,
                                   xform: Split::IntoMultipleColumns,
                                   xformopt: {
                                     field: :summary,
                                     sep: ':',
                                     max_segments: 2
                                   })
              expect(result).to eq(expected)
            end
          end

          context 'and warnfield given' do
            rows = [
              ['id', 'summary'],
              [1, 'overall: 8x10; base: 7x7']
            ]
            @info = []
            before do
              generate_csv(test_csv, rows)
            end
            it 'splits into two columns and adds warning to warnfield' do
              expected = [
                {id: '1', summary0: 'overall', summary1: '8x10; base: 7x7',
                 warn: 'max_segments less than total number of split segments'}
              ]
              result = execute_job(filename: test_csv,
                                   xform: Split::IntoMultipleColumns,
                                   xformopt: {
                                     field: :summary,
                                     sep: ':',
                                     max_segments: 2,
                                     warnfield: :warn
                                   })
              expect(result).to eq(expected)
            end
          end
          end

          context 'and collapse_on = :left' do
            context 'and no warnfield given' do
              rows = [
                ['id', 'summary'],
                [1, 'overall: 8x10; base: 7x7']
              ]
              @info = []
              before do
                generate_csv(test_csv, rows)
              end
              it 'splits into two columns' do
                expected = [
                  {id: '1', summary0: 'overall: 8x10; base', summary1: '7x7'}
                ]
                result = execute_job(filename: test_csv,
                                     xform: Split::IntoMultipleColumns,
                                     xformopt: {
                                       field: :summary,
                                       sep: ':',
                                       max_segments: 2,
                                       collapse_on: :left
                                     })
                expect(result).to eq(expected)
              end
            end
          end

          context 'and value = overall: 8x10 ; 7x7' do
            context 'and warnfield given' do
              rows = [
                ['id', 'summary'],
                [1, 'overall: 8x10 ; 7x7']
              ]
              @info = []
              before do
                generate_csv(test_csv, rows)
              end
              it 'splits into two columns' do
                expected = [
                  {id: '1', summary0: 'overall', summary1: '8x10 ; 7x7', warn: nil}
                ]
                result = execute_job(filename: test_csv,
                                     xform: Split::IntoMultipleColumns,
                                     xformopt: {
                                       field: :summary,
                                       sep: ':',
                                       max_segments: 2,
                                       warnfield: :warn
                                     })
                expect(result).to eq(expected)
              end
            end
          end
        end
      end
    end
  end
end
