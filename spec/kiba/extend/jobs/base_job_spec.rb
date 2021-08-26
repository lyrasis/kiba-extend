# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength
RSpec.describe 'Kiba::Extend::Jobs::BaseJob' do
  before(:context) do
    Kiba::Extend.config.registry = Kiba::Extend::FileRegistry.new
    entries = { base_src: {path: File.join(fixtures_dir, 'base_job_base.csv'), supplied: true},
               base_lookup: {path: File.join(fixtures_dir, 'base_job_lookup.csv'), supplied: true, lookup_on: :letter},
               base_dest: {path: File.join(fixtures_dir, 'base_job_dest.csv'), creator: Helpers.method(:base_job)},
              }
    entries.each{ |key, data| Kiba::Extend.registry.register(key, data) }
    transform_registry
  end

  let(:job){ Helpers.base_job }
  it 'blah' do
    job.run
  end
  
end
# rubocop:enable Metrics/BlockLength
