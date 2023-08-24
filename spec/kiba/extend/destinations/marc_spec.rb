# frozen_string_literal: true

require "marc"
require "spec_helper"

RSpec.describe Kiba::Extend::Destinations::Marc do
  before(:all) { @test_filename = "output.mrc" }
  after(:each) { File.delete(@test_filename) if File.exist?(@test_filename) }

  let(:testfile) { @test_filename }

  def run_job(output)
    input = marc_file

    job = Kiba.parse do
      source Kiba::Extend::Sources::Marc, filename: input
      destination Kiba::Extend::Destinations::Marc, filename: output
    end

    Kiba.run(job)
  end

  def read_results(output)
    recs = []
    MARC::Reader.new(output).each { |rec| recs << rec }
    recs
  end

  describe "#write" do
    it "produces CSV as expected" do
      run_job(testfile)
      recs = read_results(testfile)
      expect(recs.length).to eq(10)
    end
  end
end
