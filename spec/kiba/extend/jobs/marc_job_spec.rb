# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength
RSpec.describe 'Kiba::Extend::Jobs::MarcJob' do
  subject(:marcjob) do
    Kiba::Extend::Jobs::MarcJob.new(files: config, transformer: xforms)
  end

  before(:all) do
    reg = Kiba::Extend::Registry::FileRegistry.new
    Kiba::Extend.config.registry = reg
    @dest_file = File.join(fixtures_dir, 'marc_job_dest.csv')
    entries = {
      marc_src: {
        path: File.join(fixtures_dir, 'harvard_open_data.mrc'),
        supplied: true,
        src_class: Kiba::Extend::Sources::Marc
      },
      marc_dest: {
        path: @dest_file,
        creator: Helpers.method(:fake_creator_method)
      }
    }
    entries.each { |key, data| Kiba::Extend.registry.register(key, data) }
    transform_registry
  end
  before(:each) do
    FileUtils.rm(@dest_file) if File.exist?(@dest_file)
  end
  after(:each) do
    FileUtils.rm(@dest_file) if File.exist?(@dest_file)
  end

  let(:config) do
    {
      source: [:marc_src],
      destination: [:marc_dest]
    }
  end
  let(:xforms) do
    Kiba.job_segment do
      transform Kiba::Extend::Transforms::Marc::Extract245Title
    end
  end

  it 'runs and produces expected result' do
    marcjob
    result = CSV.table(@dest_file)
    expect(result).to be_a(CSV::Table)
  end

end
# rubocop:enable Metrics/BlockLength
