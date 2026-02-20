# frozen_string_literal: true

require "spec_helper"

class JobTestClass
  include Kiba::Extend::JobTest::CsvJob::Testable

  def initialize(config)
    initialization_logic(config)
  end
end

RSpec.describe Kiba::Extend::JobTest::CsvJob::Testable do
  subject(:test) { JobTestClass.new(config) }

  let(:config) { {path: File.join(fixtures_dir, "existing.csv")} }

  describe "#job_data" do
    let(:result) { test.send(:job_data) }

    it "returns CSV::Table" do
      expect(result).to be_a(CSV::Table)
    end
  end
end
