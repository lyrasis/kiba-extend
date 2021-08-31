# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Split do
  describe 'IntoMultipleColumns' do
    before(:each) do
      generate_csv(rows)
    end
    context 'without max_segments param' do
      let(:rows) {
        [
          %w[summary],
          ['']
        ]
      }
      let(:result) {
        execute_job(filename: test_csv,
                    xform: Split::IntoMultipleColumns,
                    xformopt: {
                      field: :summary,
                      sep: ':'
                    })
      }
      it 'raises ArgumentError with expected message' do
        expect { result }.to raise_error(ArgumentError, 'missing keyword: :max_segments')
      end
    end

    context 'when sep = : and value = a:b and c' do
      let(:rows) {
        [
          %w[summary],
          ['a:b'],
          ['c'],
          [':d']
        ]
      }

      context 'with max_segments = 2' do
        it 'fills in blank field before @sep with empty string and empty extra columns to the right with nil' do
          expected = [
            { summary0: 'a', summary1: 'b' },
            { summary0: 'c', summary1: nil },
            { summary0: '', summary1: 'd' },
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
    end

    context 'and max_segments = 3' do
      context 'and value = a:b:c:d:e' do
        let(:rows) {
          [
            %w[summary],
            ['a:b:c:d:e'],
            ['f:g'],
            [''],
            [nil]
          ]
        }
        context 'and collapse_on = :right' do
          context 'and no warnfield given' do
            it 'collapses on right' do
              expected = [
                { summary0: 'a', summary1: 'b', summary2: 'c:d:e' },
                { summary0: 'f', summary1: 'g', summary2: nil },
                { summary0: '', summary1: nil, summary2: nil },
                { summary0: nil, summary1: nil, summary2: nil }
              ]
              result = execute_job(filename: test_csv,
                                   xform: Split::IntoMultipleColumns,
                                   xformopt: {
                                     field: :summary,
                                     sep: ':',
                                     max_segments: 3
                                   })
              expect(result).to eq(expected)
            end
          end

          context 'and warnfield given' do
            it 'collapses on right and adds warning to warnfield' do
              expected = [
                { summary0: 'a', summary1: 'b', summary2: 'c:d:e',
                  warn: 'max_segments less than total number of split segments' },
                { summary0: 'f', summary1: 'g', summary2: nil,
                  warn: nil },
                { summary0: '', summary1: nil, summary2: nil, warn: nil },
                { summary0: nil, summary1: nil, summary2: nil, warn: nil }

              ]
              result = execute_job(filename: test_csv,
                                   xform: Split::IntoMultipleColumns,
                                   xformopt: {
                                     field: :summary,
                                     sep: ':',
                                     max_segments: 3,
                                     warnfield: :warn
                                   })
              expect(result).to eq(expected)
            end
          end
        end

        context 'and collapse_on = :left' do
          context 'and no warnfield given' do
            it 'collapses on left' do
              expected = [
                { summary0: 'a:b:c', summary1: 'd', summary2: 'e' },
                { summary0: 'f', summary1: 'g', summary2: nil },
                { summary0: '', summary1: nil, summary2: nil },
                { summary0: nil, summary1: nil, summary2: nil }
              ]
              result = execute_job(filename: test_csv,
                                   xform: Split::IntoMultipleColumns,
                                   xformopt: {
                                     field: :summary,
                                     sep: ':',
                                     max_segments: 3,
                                     collapse_on: :left
                                   })
              expect(result).to eq(expected)
            end
          end
        end
      end
    end
  end
end
