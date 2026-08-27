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

    # convenience function to avoid breaking tests due to
    # invalid fixtures and to cross-check the output of the
    # 'skip invalid XML' test
    def valid_xml_count(glob_pattern)
      Dir.glob(glob_pattern).count do |fpath|
        Nokogiri::XML(File.open(fpath)).errors.empty?
      end
    end

    it "yields the correct number of documents (recursive: false)" do
      source = src.new(dirpath: path, recursive: false, silent_warnings: true)
      expected = valid_xml_count(File.join(path, "*.xml"))
      expect(source.count).to eq expected
    end

    it "yields the correct number of documents (recursive: true)" do
      source = src.new(dirpath: path, recursive: true, silent_warnings: true)
      expected = valid_xml_count(File.join(path, "**", "*.xml"))
      expect(source.count).to eq expected
    end

    it "warns on stdout and skips yielding a document for invalid XML" do
      source = src.new(dirpath: path, silent_warnings: false)
      docs = []

      expect do
        source.each { |doc| docs << doc }
      end.to output(/is not well-formed XML/).to_stdout

      expect(docs).to all(be_a(Nokogiri::XML::Document))
      expect(docs.length).to eq valid_xml_count(File.join(path, "*.xml"))
    end
  end
end
