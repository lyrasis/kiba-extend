# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Kiba::Extend::Jobs::XmlJob" do
  subject(:xmljob) do
    Kiba::Extend::Jobs::XmlJob.new(files: config, transformer: xforms)
  end

  context "with XmlDir source, XmlDir dest" do
    before(:context) do
      reg = Kiba::Extend::Registry::FileRegistry.new
      Kiba::Extend.config.registry = reg
      @src_dir = File.join(fixtures_dir, "xml_dir")
      @dest_dir = File.join(tmp_dir, "xml_job_dest")
      entries = {
        xml_src: {
          path: @src_dir,
          supplied: true,
          src_class: Kiba::Extend::Sources::XmlDir
        },
        xml_dest: {
          path: @dest_dir,
          creator: Helpers.method(:fake_creator_method),
          dest_class: Kiba::Extend::Destinations::XmlDir
        }
      }
      entries.each { |key, data| Kiba::Extend.registry.register(key, data) }
      transform_registry
    end
    after(:context) do
      Kiba::Extend.reset_config
      FileUtils.rm_r(@dest_dir) if Dir.exist?(@dest_dir)
    end

    let(:config) do
      {
        source: [:xml_src],
        destination: [:xml_dest]
      }
    end

    let(:xforms) do
      Kiba.job_segment do
      end
    end

    it "runs and creates the destination directory" do
      xmljob.run
      expect(Dir.exist?(@dest_dir)).to be true
    end
  end
end
