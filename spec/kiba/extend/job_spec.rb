# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Job do
  describe ".output?" do
    let(:result) { Kiba::Extend::Job.output?(key) }

    context "when key not registered" do
      let(:key) { :foo__bar }

      it "returns false" do
        expect(result).to be false
      end
    end

    context "when job file already exists" do
      before(:context) do
        Kiba::Extend.config.registry = Kiba::Extend::Registry::FileRegistry
        prepare_registry
      end
      after(:context) { Kiba::Extend.reset_config }
      let(:key) { :foo }

      it "returns true" do
        expect(result).to be true
      end
    end

    context "when job file does not exist" do
      before(:each) do
        Kiba::Extend.config.registry = Kiba::Extend::Registry::FileRegistry
        prepare_registry
      end
      after(:each) { Kiba::Extend.reset_config }

      context "when job output is 0 rows" do
        let(:key) { :noresultfile }

        it "returns false" do
          expect(result).to be false
        end
      end

      context "when job output has rows" do
        let(:key) { :resultfile }

        it "returns true" do
          expect(result).to be true
        end
      end
    end

    context "when job has JSON destination" do
      before(:context) do
        Kiba::Extend.config.registry = Kiba::Extend::Registry::FileRegistry
        prepare_registry
      end
      after(:context) { Kiba::Extend.reset_config }
      let(:key) { :json_arr }

      it "returns true" do
        expect(result).to be true
      end
    end
  end
end
