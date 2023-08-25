# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Data::ConvertibleFraction do
  subject(:klass) { described_class }

  describe ".initialize" do
    let(:result) { klass.new(**params) }

    context "when `whole` is not an Integer" do
      let(:params) { {whole: "1", fraction: "3/4", position: 2..4} }

      it "raises TypeError" do
        expect {
          result
        }.to raise_error(TypeError, "`whole` must be an Integer")
      end
    end

    context "when `position` is not a Range" do
      let(:params) { {whole: 1, fraction: "3/4", position: 2} }

      it "raises TypeError" do
        expect {
          result
        }.to raise_error(TypeError, "`position` must be a Range")
      end
    end
  end

  describe "#to_h" do
    it "returns Hash" do
      cf = klass.new(fraction: "1/2", position: 0..2)
      expected = {whole: 0, fraction: "1/2", position: 0..2}
      expect(cf.to_h).to eq(expected)
    end
  end

  describe "#replace_in" do
    let(:expectations) do
      {
        [{whole: 0, fraction: "2/3", position: 6..8},
          "about 2/3 inch"] => "about 0.6667 inch",
        [{whole: 0, fraction: "1/2", position: 0..2},
          "1/2 inch"] => "0.5 inch",
        [{whole: 0, fraction: "1/2", position: 6..8},
          "about 1/2"] => "about 0.5",
        [{whole: 0, fraction: "1/0", position: 6..8},
          "about 1/0 inch"] => "about 1/0 inch"
      }
    end
    let(:results) do
      expectations.keys.map { |arr|
        klass.new(**arr[0]).replace_in(val: arr[1])
      }
    end
    let(:expected) { expectations.values }

    it "behaves as expected" do
      expect(results).to eq(expected)
    end
  end

  describe "#to_f" do
    let(:expectations) do
      {
        {whole: 0, fraction: "1/2", position: 0..2} => 0.5,
        {whole: 1, fraction: "3/4", position: 0..2} => 1.75,
        {whole: 1, fraction: "3/0", position: 0..2} => nil
      }
    end
    let(:results) do
      expectations.keys.map { |params| klass.new(**params).to_f }
    end
    let(:expected) { expectations.values }

    it "behaves as expected" do
      expect(results).to eq(expected)
    end
  end

  describe "#to_s" do
    let(:expectations) do
      {
        {whole: 0, fraction: "1/2", position: 0..2} => "0.5",
        {whole: 1, fraction: "3/4", position: 0..2} => "1.75",
        {whole: 1, fraction: "3/0", position: 0..2} => nil,
        {whole: 1, fraction: "2/3", position: 0..2} => "1.6667"
      }
    end
    let(:results) do
      expectations.keys.map { |params| klass.new(**params).to_s }
    end
    let(:expected) { expectations.values }

    it "behaves as expected" do
      expect(results).to eq(expected)
    end

    context "with places: 1" do
      let(:expectations) do
        {
          {whole: 0, fraction: "1/2", position: 0..2} => "0.5",
          {whole: 1, fraction: "3/4", position: 0..2} => "1.8",
          {whole: 1, fraction: "3/0", position: 0..2} => nil,
          {whole: 1, fraction: "2/3", position: 0..2} => "1.7"
        }
      end
      let(:results) do
        expectations.keys.map { |params| klass.new(**params).to_s(1) }
      end
      let(:expected) { expectations.values }

      it "behaves as expected" do
        expect(results).to eq(expected)
      end
    end
  end

  describe "#convertible?" do
    let(:expectations) do
      {
        {whole: 0, fraction: "1/2", position: 0..2} => true,
        {whole: 0, fraction: "1/0", position: 0..2} => false
      }
    end
    let(:results) do
      expectations.keys.map { |params| klass.new(**params).convertible? }
    end
    let(:expected) { expectations.values }

    it "behaves as expected" do
      expect(results).to eq(expected)
    end
  end

  describe "#==" do
    let(:expectations) do
      {
        [{whole: 0, fraction: "1/2", position: 0..2},
          {fraction: "1/2", position: 0..2}] => true,
        [{whole: 1, fraction: "1/2", position: 0..2},
          {whole: 0, fraction: "1/2", position: 0..2}] => false
      }
    end
    let(:results) do
      expectations.keys.map { |pair|
        klass.new(**pair[0]) == klass.new(**pair[1])
      }
    end
    let(:expected) { expectations.values }

    it "behaves as expected" do
      expect(results).to eq(expected)
    end
  end

  describe "#<=>" do
    it "behaves as expected" do
      arr = [
        klass.new(fraction: "1/2", position: 27..29),
        klass.new(fraction: "1/2", position: 0..2),
        klass.new(fraction: "1/2", position: 5..7),
        klass.new(fraction: "1/2", position: 100..102)
      ]
      expected = [0..2, 5..7, 27..29, 100..102]
      expect(arr.sort.map(&:position)).to eq(expected)
    end
  end

  describe "#hash" do
    let(:expectations) do
      {
        [{whole: 0, fraction: "1/2", position: 0..2},
          {whole: 0, fraction: "1/2", position: 0..2}] => true,
        [{whole: 1, fraction: "1/2", position: 0..2},
          {whole: 0, fraction: "1/2", position: 0..2}] => false
      }
    end
    let(:results) do
      expectations.keys.map { |pair|
        klass.new(**pair[0]).hash == klass.new(**pair[1]).hash
      }
    end
    let(:expected) { expectations.values }

    it "behaves as expected" do
      expect(results).to eq(expected)
    end
  end
end
