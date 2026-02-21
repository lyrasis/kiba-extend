# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::JobTest::ConfigFilePrepper do
  subject(:prepper) { described_class.new(path) }

  let(:path) { File.join(fixtures_dir, "job_tests", "some_tests.yml") }

  describe "call" do
    let(:result) { prepper.call }

    it "returns Array of Hash test configs" do
      expect(result).to be_a(Array)
      first = result.first
      expect(first[:srcfile]).to eq(path)
      expect(first[:srcline]).to eq(5)
      expect(first[:test]).to eq("CsvJob::Equal")
      expect(first[:job]).to eq(:fkey)
    end
  end
end
