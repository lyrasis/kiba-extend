# frozen_string_literal: true

require "spec_helper"

# rubocop:disable Metrics/BlockLength
RSpec.describe "Kiba::Extend::Registry::RegisteredDestination" do
  let(:filekey) { :fkey }
  let(:path) { File.join("spec", "fixtures", "fkey.csv") }
  let(:default) { {path: path} }
  let(:default_desc) { {path: path, desc: "description"} }
  let(:dest) do
    Kiba::Extend::Registry::RegisteredDestination.new(
      key: filekey,
      data: Kiba::Extend::Registry::FileRegistryEntry.new(data),
      for_job: :foo
    )
  end
  let(:optres) { {csv_options: Kiba::Extend.csvopts} }

  describe "#new" do
    context "with supplied entry" do
      let(:data) { {path: path, supplied: true} }

      it "raises error" do
        expect { dest }.to raise_error(
          Kiba::Extend::Registry::RegisteredDestination::SuppliedEntryError
        )
      end
    end
  end

  describe "#args" do
    let(:result) { dest.args }
    context "with basic defaults" do
      let(:data) { default }
      let(:expected) do
        {filename: path}.merge(optres)
      end
      it "returns with Kiba::Extend csvopts" do
        expect(result).to eq(expected)
      end
    end

    context "with given options" do
      let(:override_opts) { {foo: :bar} }
      let(:data) { {path: path, dest_opt: override_opts} }
      let(:expected) do
        {filename: path, csv_options: override_opts}
      end
      it "returns with given opts" do
        expect(result).to eq(expected)
      end
    end

    context "with extra options" do
      context "when extra option is allowed for destination class" do
        let(:extra) { {initial_headers: %i[a b]} }
        let(:data) do
          {path: path, dest_class: Kiba::Extend::Destinations::CSV,
           dest_special_opts: extra}
        end
        let(:expected) do
          {filename: path, csv_options: Kiba::Extend.csvopts,
           initial_headers: %i[a b]}
        end
        it "returns with extra options" do
          expect(result).to eq(expected)
        end
      end

      context "when extra option is not defined for destination class" do
        let(:extra) { {blah: %i[a b]} }
        let(:data) do
          {path: path, dest_class: Kiba::Extend::Destinations::CSV,
           dest_special_opts: extra}
        end
        let(:expected) do
          {filename: path, csv_options: Kiba::Extend.csvopts}
        end
        it "returns without extra options" do
          expect(result).to eq(expected)
        end
        it "warns about unsupported options" do
          # rubocop:todo Layout/LineLength
          msg = "WARNING: Destination file :#{filekey} is called with special option :blah, which is unsupported by Kiba::Extend::Destinations::CSV\n"
          # rubocop:enable Layout/LineLength
          expect { dest.args }.to output(msg).to_stdout
        end
      end
    end
  end

  describe "#description" do
    let(:result) { dest.description }
    context "when not given" do
      let(:data) { default }
      it "returns empty string" do
        expect(result).to eq("")
      end
    end

    context "when given" do
      let(:data) { default_desc }
      it "returns given value" do
        expect(result).to eq("description")
      end
    end
  end

  describe "#klass" do
    let(:result) { dest.klass }
    context "with basic defaults" do
      let(:data) { default }
      it "returns Kiba::Extend default destination class" do
        expect(result).to eq(Kiba::Extend.destination)
      end
    end

    context "with a given class" do
      let(:override_klass) { Kiba::Extend::Sources::Marc }
      let(:data) { {path: path, dest_class: override_klass} }
      it "returns given class" do
        expect(result).to eq(override_klass)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
