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

    # The logic of these tests is: the first one should succeed
    # because `<ns2:relations_common>` is what appears in the
    # document, and that element shouldn’t be reachable without
    # specifying its namespace explicitly. The second one should
    # succeed because we’ve removed the ‘ns2’ namespace.
    it "keeps namespaces by default" do
      source = src.new(dirpath: path, silent_warnings: true, recursive: false)
      doc = source.first
      expect(doc.at_xpath("//relations_common")).to be_nil
    end

    it "strips namespaces when remove_namespaces: true" do
      source = src.new(dirpath: path, silent_warnings: true,
        recursive: false, remove_namespaces: true)
      doc = source.first
      expect(doc.at_xpath("//relations_common")).not_to be_nil
    end

    it "warns on stdout and skips yielding a document for invalid XML" do
      source = src.new(dirpath: path, silent_warnings: false)
      docs = []

      # Note that if Nokogiri error messages change, this code will
      # need to be updated. The goal is just to ensure that the
      # error message is sent to stdout.
      expect do
        source.each { |doc| docs << doc }
      end.to output(/is not well-formed XML/).to_stdout

      expect(docs).to all(be_a(Nokogiri::XML::Document))
      expect(docs.length).to eq valid_xml_count(File.join(path, "*.xml"))
    end

    # See if it's possible to pass a bitmask of custom options to the
    # source constructor via the `parseopts` argument. All the options are
    # described at https://nokogiri.org/rdoc/Nokogiri/XML/ParseOptions.html.
    #
    # In this case, we use safe/standard options. RECOVER must always be
    # passed, NOBLANKS removes blank elements, and NONET forbids network
    # egress to get resources such as DTDs. Warnings are silenced for this
    # test and most other XML tests to avoid spam about `invalid.xml`;
    # the test would fail for other reasons than malformed XML.
    it "accepts custom parsing options" do
      opts = Nokogiri::XML::ParseOptions::RECOVER |
        Nokogiri::XML::ParseOptions::NOBLANKS |
        Nokogiri::XML::ParseOptions::NONET
      source = src.new(dirpath: path, silent_warnings: true,
        recursive: false, parseopts: opts)
      doc = source.first
      expect(doc.root.children.map(&:name)).to eq(["relations_common"])
    end
  end
end
