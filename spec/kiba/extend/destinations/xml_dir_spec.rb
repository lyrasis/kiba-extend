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

  describe "#write" do
    def written_basenames
      Dir.glob(File.join(dirpath, "*.xml")).map { |fpath| File.basename(fpath) }
        .sort
    end

    def run_job(input, output)
      job = Kiba.parse do
        source Kiba::Extend::Sources::XmlDir, dirpath: input,
          silent_warnings: true
        destination Kiba::Extend::Destinations::XmlDir, dirpath: output
      end

      Kiba.run(job)
    end

    it "reuses the source filename for each document, since XmlDir "\
      "source Documents may carry a usable .url" do
      input = File.join(fixtures_dir, "xml_dir")
      expected = Dir.glob(File.join(input, "*.xml"))
        .select { |fpath| Nokogiri::XML(File.open(fpath)).errors.empty? }
        .map { |fpath| File.basename(fpath) }
        .sort

      run_job(input, dirpath)

      expect(written_basenames).to eq expected
    end

    it "falls back to a sequential, zero-padded filename when the row "\
      "has no usable .url" do
      dest = described_class.new(dirpath: dirpath)
      dest.write(Nokogiri::XML("<foo/>"))
      dest.close

      expect(written_basenames).to eq ["00001.xml"]
    end
  end
end
