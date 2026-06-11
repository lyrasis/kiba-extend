# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Command::Fcar::Chute do
  describe ".call" do
    subject(:result) { described_class.call }

    after(:each) { Kiba::Extend::Fcar.reset_config }

    context "when chute setting is Array" do
      before do
        Kiba::Extend::Fcar.config.chute = %w[
          Apple
          Orange
          Cherry
        ]
      end

      it "returns as expected" do
        expect(result).to eq("Apple\nOrange\nCherry")
      end
    end

    context "when chute setting is Hash" do
      before do
        Kiba::Extend::Fcar.config.chute = {
          "Apple" => "",
          "Orange" => "soda",
          "Cherry" => "cola"
        }
      end

      it "returns as expected" do
        expect(result).to eq("Apple\nOrange\n  soda\nCherry\n  cola")
      end
    end

    context "when chute setting is empty Hash" do
      before { Kiba::Extend::Fcar.config.chute = {} }

      it "returns as expected" do
        expect(result).to eq("")
      end
    end

    context "when chute setting is empty Array" do
      before { Kiba::Extend::Fcar.config.chute = [] }

      it "returns as expected" do
        expect(result).to eq("")
      end
    end
  end
end
