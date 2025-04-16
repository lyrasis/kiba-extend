# frozen_string_literal: true

require "spec_helper"

# rubocop:disable Metrics/BlockLength
RSpec.describe "Kiba::Extend::Registry::FileRegistry" do
  after(:each) { Kiba::Extend.reset_config }

  let(:filekey) { :fkey }
  let(:fkeypath) { File.join(fixtures_dir, "existing.csv") }
  let(:registry) { Kiba::Extend.registry }
  let(:result) { registry.resolve(filekey) }

  describe "initial setup and registration" do
    before(:each) do
      Kiba::Extend.config.registry = Kiba::Extend::Registry::FileRegistry
      populate_registry
    end

    context "when no namespace" do
      let(:data) { {path: fkeypath, supplied: true, lookup_on: :id} }
      it "registers and resolves" do
        expect(result).to eq(data)
      end

      context "with insufficient data" do
        let(:filekey) { :invalid }
        let(:data) { {} }
        it "registers and resolves" do
          expect(result).to eq(data)
        end
      end
    end

    context "with namespace" do
      it "registers and resolves" do
        expect(registry.resolve("ns__sub__fkey")).to eq({path: fkeypath,
                                                         supplied: true})
      end
    end
  end

  describe "transformation" do
    context "when a supplied file does not exist" do
      before(:each) do
        Kiba::Extend.config.registry = Kiba::Extend::Registry::FileRegistry
        @missing_supplied = File.join(fixtures_dir, "supplied", "not_there.csv")
        extra_entry = {
          missupp: {path: @missing_supplied, supplied: true}
        }
        populate_registry(more_entries: extra_entry)
      end

      after(:each) do
        dir = Pathname.new(@missing_supplied).dirname
        dir.delete if dir.exist?
        Kiba::Extend.reset_config
      end

      it "warns of missing file" do
        msg = <<~MSG
          #{Kiba::Extend.warning_label}: Missing supplied file: #{fixtures_dir}/supplied/not_there.csv
        MSG
        expect { transform_registry }.to output(msg).to_stdout
      end
    end

    context "when expected directories do not exist" do
      before(:each) do
        Kiba::Extend.config.registry = Kiba::Extend::Registry::FileRegistry
        @missing_dir = File.join(fixtures_dir, "working")
        extra_entry = {
          missdir: {path: File.join(@missing_dir, "test.csv"),
                    creator: Helpers.method(:test_csv)}
        }
        populate_registry(more_entries: extra_entry)
        transform_registry
      end

      after(:each) do
        Dir.delete(@missing_dir) if Dir.exist?(@missing_dir)
        Kiba::Extend.reset_config
      end

      it "creates expected directories" do
        expect(Dir.exist?(@missing_dir)).to be true
      end
    end
  end

  # subsequent tests depend on the transformation having been done here
  describe "post-transformation" do
    before(:each) do
      Kiba::Extend.config.registry = Kiba::Extend::Registry::FileRegistry
      populate_registry
      transform_registry
    end

    describe "#transform" do
      it "converts all registered items to FileRegistryEntry objects" do
        chk = []
        registry.each { |item| chk << item[1].class }
        chk.uniq!
        expect(chk.length).to eq(1)
        expect(chk.first).to eq(Kiba::Extend::Registry::FileRegistryEntry)
      end
    end

    describe "as destination" do
      let(:result) { registry.as_destination(filekey, :foo) }

      context "with job entry key" do
        let(:filekey) { :foo }

        it "returns destination file config" do
          expect(result).to be_a(Kiba::Extend::Registry::RegisteredDestination)
        end
      end

      context "with supplied entry key" do
        let(:filekey) { :fee }

        it "raises error" do
          expect { result }.to raise_error(
            Kiba::Extend::Registry::RegisteredDestination::SuppliedEntryError
          )
        end
      end

      context "when called with nonexistent key" do
        let(:filekey) { :cats }
        it "raises error" do
          msg = "No file registered under the key: :#{filekey} (as destination)"
          expect { result }.to raise_error(
            Kiba::Extend::Registry::FileRegistry::KeyNotRegisteredError, msg
          )
        end
      end
    end

    describe "as lookup" do
      let(:result) { registry.as_lookup(filekey, :foo) }
      it "returns lookup file config" do
        expect(result).to be_a(Kiba::Extend::Registry::RegisteredLookup)
      end
    end

    describe "as source" do
      let(:result) { registry.as_source(filekey, :foo) }
      it "returns source file config" do
        expect(result).to be_a(Kiba::Extend::Registry::RegisteredSource)
      end
    end

    describe "entries" do
      let(:result) { registry.entries }
      it "returns Array of FileRegistryEntries" do
        expect(result).to be_a(Array)
        expect(result.first).to be_a(Kiba::Extend::Registry::FileRegistryEntry)
      end
    end
  end

  describe "#replace_entry_x_with_entry_y" do
    let(:result) do
      registry.replace_entry_x_with_entry_y(x: "fkey", y: "baz")
      registry["fkey"]
    end

    context "pre-transformation" do
      before(:each) do
        Kiba::Extend.config.registry = Kiba::Extend::Registry::FileRegistry
        populate_registry
      end

      it "replaces entry" do
        expect(result[:supplied]).to be_nil
        expect(result[:tags]).to eq([:report])
      end
    end

    context "post-transformation" do
      before(:each) do
        Kiba::Extend.config.registry = Kiba::Extend::Registry::FileRegistry
        populate_registry
        transform_registry
      end

      it "replaces entry" do
        expect(result.supplied).to be false
        expect(result.tags).to eq([:report])
      end
    end

    context "post-finalization" do
      before(:each) do
        Kiba::Extend.config.registry = Kiba::Extend::Registry::FileRegistry
        populate_registry
        Kiba::Extend.registry.finalize
      end

      it "does not replace entry" do
        expect(result.supplied).to be true
        expect(result.tags).to eq([])
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
