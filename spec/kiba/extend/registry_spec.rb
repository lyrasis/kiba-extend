# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Registry do
  before(:all) { populate_registry }
  after(:all) { Kiba::Extend.reset_config }

  describe ".entry_for" do
    let(:result) { Kiba::Extend::Registry.entry_for(jobkey) }

    context "with unregistered job" do
      let(:jobkey) { :unr__unr }

      it "raises JobNotRegisteredError" do
        expect { result }.to raise_error(Kiba::Extend::JobNotRegisteredError)
      end
    end

    context "with registered job" do
      let(:jobkey) { :fee }

      it "returns registry entry" do
        expect(result).to be_a(Kiba::Extend::Registry::FileRegistryEntry)
      end
    end
  end
end
