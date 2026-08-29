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
          src_class: Kiba::Extend::Sources::XmlDir,
          src_opt: {silent_warnings: true}
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

  # The above test, but with custom parsing options. The bitmask keeps
  # RECOVER (for the purposes of kiba-extend, this is required) and
  # instructs Nokogiri to collapse blank nodes to singletons (<z></z> => <z/>),
  # forbid network egress for DTDs or other resources, and remove redundant
  # namespaces.
  #
  # @note I don't know how granular we want this testing to be. The job
  #   works as expected and can be confirmed by removing the call to
  #   FileUtils.rm_r on the destination directory and inspecting 1.xml,
  #   which illustrates the redundant namespacing and singleton transforms,
  #   but testing that output veers into testing Nokogiri, not testing
  #   kiba-extend.
  context "with XmlDir source, XmlDir dest, and custom parse options" do
    before(:context) do
      reg = Kiba::Extend::Registry::FileRegistry.new
      Kiba::Extend.config.registry = reg
      @src_dir = File.join(fixtures_dir, "xml_dir")
      @dest_dir = File.join(tmp_dir, "xml_job_custom_parseopts_dest")
      opts = Nokogiri::XML::ParseOptions::RECOVER |
        Nokogiri::XML::ParseOptions::NOBLANKS |
        Nokogiri::XML::ParseOptions::NONET |
        Nokogiri::XML::ParseOptions::NSCLEAN
      entries = {
        xml_src: {
          path: @src_dir,
          supplied: true,
          src_class: Kiba::Extend::Sources::XmlDir,
          src_opt: {parseopts: opts, silent_warnings: true}
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

    let(:captured) { [] }

    let(:xforms) do
      capture = captured
      Kiba.job_segment do
        transform do |doc|
          capture << doc.root.children.map(&:name)
          doc
        end
      end
    end

    it "parses source xml using the given parse options" do
      xmljob.run
      expect(captured).to all(eq(["relations_common"]))
    end
  end
end
