# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Kiba::Extend::Sources::XmlDir" do
  subject(:src) { Kiba::Extend::Sources::XmlDir }
  let(:path) { File.join(fixtures_dir, "xml_dir") }

  describe "#each" do
    it "yields Nokogiri::XML::Documents" do
      source = src.new(dirpath: path, silent_warnings: true)
      source.each do |doc|
        expect(doc.is_a?(Nokogiri::XML::Document)).to eq true
      end
    end

    it "yields the correct number of documents (recursive: false)" do
      source = src.new(dirpath: path, recursive: false, silent_warnings: true)
      expected = Dir.glob(File.join(path, "*.xml")).length
      expect(source.count).to eq expected
    end

    it "yields the correct number of documents (recursive: true)" do
      source = src.new(dirpath: path, recursive: true, silent_warnings: true)
      expected = Dir.glob(File.join(path, "**", "*.xml")).length
      expect(source.count).to eq expected
    end

    it "warns on stdout with silent_warnings = false, still yields"\
      " a document for invalid XML" do
      source = src.new(dirpath: path, silent_warnings: false)
      docs = []

      expect do
        source.each { |doc| docs << doc }
      end.to output(/is not well-formed XML/).to_stdout

      expect(docs).to all(be_a(Nokogiri::XML::Document))
    end
  end
end
