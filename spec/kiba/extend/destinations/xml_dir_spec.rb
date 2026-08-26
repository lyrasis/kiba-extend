# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Destinations::XmlDir do
  let(:dirpath) { File.join(tmp_dir, "xml_dir_dest") }

  after(:each) { FileUtils.rm_r(dirpath) if Dir.exist?(dirpath) }

  describe "#initialize" do
    it "creates the destination directory if it does not exist" do
      expect(Dir.exist?(dirpath)).to be false
      described_class.new(dirpath: dirpath)
      expect(Dir.exist?(dirpath)).to be true
    end
  end
end
