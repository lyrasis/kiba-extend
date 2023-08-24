# frozen_string_literal: true

RSpec.describe Kiba::Extend::Transforms::Helpers::OrgNameChecker do
  subject(:checker) { described_class.new(**params) }

  describe "#call" do
    let(:results) { vals.keys.map { |val| [val, checker.call(val)] }.to_h }
    let(:params) { {} }

    context "with default params" do
      let(:vals) do
        {
          "Acme, LLC." => true,
          "Acme Co" => true,
          "Acme Co." => true,
          "Co Cooper" => false,
          "Art dept." => true,
          "Art Dept" => true,
          "Art department" => true,
          "Dept. of the Interior" => true,
          "Crimethinc" => false,
          "Acme, Inc" => true,
          "Acme, Inc." => true,
          "Napo & El" => true,
          "Hops, Munstead, & Vern" => true,
          "Napo and El" => true,
          "Hops, Munstead and Vern" => true,
          "Smith family" => false,
          "Plumbing" => false,
          "Hilton Hotels" => true,
          "Durham Hotel" => true,
          "Insurance." => false
        }
      end

      it "returns expected" do
        expect(results).to eq(vals)
      end
    end

    context "with added pattern" do
      let(:params) { {added_patterns: [/inc$/]} }
      let(:vals) do
        {
          "Crimethinc" => true
        }
      end

      it "returns expected" do
        expect(results).to eq(vals)
      end
    end

    context "with family_is_org" do
      let(:params) { {family_is_org: true} }
      let(:vals) do
        {
          "Smith Family" => true
        }
      end

      it "returns expected" do
        expect(results).to eq(vals)
      end
    end
  end
end
