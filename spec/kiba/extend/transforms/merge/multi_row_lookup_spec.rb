# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Merge::MultiRowLookup do
  let(:accumulator){ [] }
  let(:test_job){ Helpers::TestJob.new(input: input, accumulator: accumulator, transforms: transforms) }
  let(:result){ test_job.accumulator }

  context 'when multikey = false (default)' do
    let(:input) do
      [
        {id: '1', name: 'Weddy', sex: 'm', source: 'adopted'},
        {id: '2', name: 'Kernel', sex: 'f', source: 'adopted'},
        {id: '3', name: 'Boris', sex: 'm', source: 'adopted'},
        {id: '4', name: 'Earlybird', sex: 'f', source: 'hatched'},
        {id: '5', name: 'Lazarus', sex: 'm', source: 'adopted'},
        {id: nil, name: 'Null', sex: '', source: ''}
      ]
    end

    let(:transforms) do
      Kiba.job_segment do
        transform Merge::MultiRowLookup,
          fieldmap: {
            date: :date,
            event: :treatment
          },
          keycolumn: :id,
          lookup: {
            "1"=>[
              {:id=>"1", :date=>"2019-07-21", :treatment=>"hatch"},
              {:id=>"1", :date=>"2019-09-15", :treatment=>"adopted"},
              {:id=>"1", :date=>"2020-04-15", :treatment=>"deworm"}
            ],
            "2"=>[
              {:id=>"2", :date=>"2019-08-01", :treatment=>"hatch"},
              {:id=>"2", :date=>"2019-09-15", :treatment=>"adopted"},
              {:id=>"2", :date=>"2020-04-15", :treatment=>"deworm"}
            ],
            "4"=>[
              {:id=>"4", :date=>"", :treatment=>""}
            ]
          }
      end
    end

    let(:expected) do
      [
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
    end
    it 'merges values from specified fields into multivalued fields' do
      expect(result).to eq(expected)
    end

    context 'with constantmap specified' do
      let(:transforms) do
        Kiba.job_segment do
          transform Merge::MultiRowLookup,
            fieldmap: {
              date: :date,
              event: :treatment
            },
            lookup: {
              "1"=>[
                {:id=>"1", :date=>"2019-07-21", :treatment=>"hatch"},
                {:id=>"1", :date=>"2019-09-15", :treatment=>"adopted"},
                {:id=>"1", :date=>"2020-04-15", :treatment=>"deworm"}
              ],
              "2"=>[
                {:id=>"2", :date=>"2019-08-01", :treatment=>"hatch"},
                {:id=>"2", :date=>"2019-09-15", :treatment=>"adopted"},
                {:id=>"2", :date=>"2020-04-15", :treatment=>"deworm"}
              ],
              "4"=>[
                {:id=>"4", :date=>"", :treatment=>""}
              ]
            },
            keycolumn: :id,
            constantmap: { by: 'kms', loc: 'The Thicket' }
        end
      end
      
      let(:expected) do
        [
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
      end

      it 'merges specified constant values into specified fields for each row merged' do
        expect(result).to eq(expected)
      end
    end
  end

  context 'when multikey = true' do
    let(:input) do
      [
        {single: 'a|b|c'},
        {single: 'd'},
        {single: 'e|f|g'},
        {single: 'h'},
        {single: nil}
      ]
    end

    let(:expected) do
      [
        { single: 'a|b|c', doubles: 'aa|bb|beebee|cc', triples: 'aaa|bbb||ccc' },
        { single: 'd', doubles: 'dd', triples: 'ddd' },
        { single: 'e|f|g', doubles: 'ee|', triples: 'eee|ggg' },
        { single: 'h', doubles: nil, triples: nil },
        { single: nil, doubles: nil, triples: nil }
      ]
    end
    
    let(:lookup) { Lookup.csv_to_multi_hash(file: lookup_csv, csvopt: CSVOPT, keycolumn: :single) }

    let(:transforms) do
      Kiba.job_segment do
        transform Merge::MultiRowLookup,
            fieldmap: {
              doubles: :double,
              triples: :triple
            },
            keycolumn: :single,
            multikey: true,
            delim: '|',
            lookup: {
              "a"=>[
                {:single=>"a", :double=>"aa", :triple=>"aaa"}
              ],
              "b"=>[
                {:single=>"b", :double=>"bb", :triple=>"bbb"},
                {:single=>"b", :double=>"beebee", :triple=>""}
              ],
              "c"=>[
                {:single=>"c", :double=>"cc", :triple=>"ccc"}
              ],
              "d"=>[
                {:single=>"d", :double=>"dd", :triple=>"ddd"}
              ],
              "e"=>[
                {:single=>"e", :double=>"ee", :triple=>"eee"}
              ],
              "g"=>[
                {:single=>"g", :double=>"", :triple=>"ggg"}
              ]
            }
      end
    end

    it 'merges values from specified fields into multivalued fields' do
      expect(result).to eq(expected)
    end

    context 'with constantmap' do
      let(:expected) do
        [
          { single: 'a|b|c', doubles: 'aa|bb|beebee|cc', triples: 'aaa|bbb||ccc', quad: '4|4|4|4', pent: '5|5|5|5' },
          { single: 'd', doubles: 'dd', triples: 'ddd', quad: '4', pent: '5' },
          { single: 'e|f|g', doubles: 'ee|', triples: 'eee|ggg', quad: '4|4', pent: '5|5' },
          { single: 'h', doubles: nil, triples: nil, quad: nil, pent: nil },
          { single: nil, doubles: nil, triples: nil, quad: nil, pent: nil }
        ]
      end

      let(:transforms) do
        Kiba.job_segment do
          transform Merge::MultiRowLookup,
              fieldmap: {
                doubles: :double,
                triples: :triple
              },
              lookup: {
                "a"=>[
                  {:single=>"a", :double=>"aa", :triple=>"aaa"}
                ],
                "b"=>[
                  {:single=>"b", :double=>"bb", :triple=>"bbb"},
                  {:single=>"b", :double=>"beebee", :triple=>""}
                ],
                "c"=>[
                  {:single=>"c", :double=>"cc", :triple=>"ccc"}
                ],
                "d"=>[
                  {:single=>"d", :double=>"dd", :triple=>"ddd"}
                ],
                "e"=>[
                  {:single=>"e", :double=>"ee", :triple=>"eee"}
                ],
                "g"=>[
                  {:single=>"g", :double=>"", :triple=>"ggg"}
                ]
              },
              keycolumn: :single,
              multikey: true,
              delim: '|',
              constantmap: { quad: 4, pent: 5 }
        end
      end
      
      it 'merges specified constant values into specified fields for each row merged' do
        expect(result).to eq(expected)
      end
    end
  end
end

