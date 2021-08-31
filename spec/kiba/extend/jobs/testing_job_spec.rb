# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength
RSpec.describe 'Kiba::Extend::Jobs::TestingJob' do
  let(:test_job) { Kiba::Extend::Jobs::TestingJob.new(files: test_job_config, transformer: test_job_transforms) }
  let(:test_job_config){ { source: src, destination: dest } }
  let(:src){ [{foo: 1, bar: 2}, {foo: 3, bar: 4}] }
  let(:dest){ [] }
  let(:test_job_transforms) do
    Kiba.job_segment do
      transform Kiba::Extend::Transforms::Rename::Field, from: :bar, to: :baz
      # transform Merge::MultiRowLookup,
      #           lookup: base_lookup,
      #           keycolumn: :alpha,
      #           fieldmap: {
      #             from_lkup: :word,
      #           },
      #           delim: Kiba::Extend.delim
    end
  end

  context 'with defaults' do
    let(:job) { test_job }
    context 'when dependency files exist' do
      it 'runs and produces expected result' do
         job
         expected = [{foo: 1, baz: 2}, {foo: 3, baz: 4}]
        expect(dest).to eq(expected)
      end
    end
  end  
end
# rubocop:enable Metrics/BlockLength
