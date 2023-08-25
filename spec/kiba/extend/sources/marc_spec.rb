# frozen_string_literal: true

require "spec_helper"

# rubocop:disable Metrics/BlockLength
RSpec.describe "Kiba::Extend::Sources::Marc" do
  let(:path) { File.join(fixtures_dir, "harvard_open_data.mrc") }
  subject(:src) { Kiba::Extend::Sources::Marc }

  describe "#each" do
    context "with filename as only param" do
      it "yields `MARC::Record`s" do
        result = []
        source = src.new(filename: path)
        source.each { |rec| result << rec }
        expect(result.length).to eq(10)
        expect(result.first).to be_a(MARC::Record)
      end
    end

    context "with filename and args" do
      it "yields `MARC::Record`s" do
        result = []
        source = src.new(filename: path, args: {external_encoding: "UTF-8"})
        source.each { |rec| result << rec }
        expect(result.length).to eq(10)
        expect(result.first).to be_a(MARC::Record)
      end
    end
  end
end

# rubocop:enable Metrics/BlockLength
