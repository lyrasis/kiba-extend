# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Extract do
  describe 'Fields' do
    let(:input) do
      [
        {foo: 'a:b', bar: 'e', baz: 'f', boo: ''},
        {foo: 'c', bar: nil, baz: 'g', boo: 'h'},
        {foo: ':d', bar: 'i:', baz: 'j', boo: 'k'}
      ]
    end
      let(:output){ [] }
      let(:test_job_config){ { source: input, destination: output } }
      let(:test_job) { Kiba::Extend::Jobs::TestingJob.new(files: test_job_config, transformer: test_job_transforms) }

      context 'with sep and source_field_track = true' do
        let(:test_job_transforms) do
          Kiba.job_segment do
            transform Extract::Fields, fields: %i[foo bar], sep: ':'
          end
        end
        it 'extracts split multivalues' do
          expected = [
            {value: 'a', from_field: :foo},
            {value: 'b', from_field: :foo},
            {value: 'e', from_field: :bar},
            {value: 'c', from_field: :foo},
            {value: 'd', from_field: :foo},
            {value: 'i', from_field: :bar}
          ]
          test_job
          expect(output).to eq(expected)
        end
      end

      context 'with no sep and source_field_track = false' do
        let(:test_job_transforms) do
          Kiba.job_segment do
            transform Extract::Fields, fields: %i[foo bar], source_field_track: false
          end
        end
        it 'extracts multivalues without splitting' do
          expected = [
            {value: 'a:b'},
            {value: 'e'},
            {value: 'c'},
            {value: ':d'},
            {value: 'i:'}
          ]
          test_job
          expect(output).to eq(expected)
        end
      end
  end
end
