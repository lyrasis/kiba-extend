# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Kiba::Extend::Sources::XmlDir" do
  subject(:src) { Kiba::Extend::Sources::XmlDir }
  # TODO - create actual fixtures
  let(:path) { File.join(fixtures_dir, "xml_dir") }

  describe "#each" do
    context "with a real EAD fixture" do
      it "yields each selected node as a parsed XML document" do
        source = src.new(
          dirpath: path,
          record_selector: ->(node) { node.name == "c01" }
        )

        titles = []
        source.each do |doc|
          titles << doc.at_xpath('//*[local-name()="unittitle"]').text
        end

        expect(titles).to eq(["Textual materials", "Graphic materials"])
      end
    end
  end
end
