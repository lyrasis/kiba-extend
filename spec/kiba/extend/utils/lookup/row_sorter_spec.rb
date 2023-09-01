# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Utils::Lookup::RowSorter do
  let(:on) { :id }
  let(:dir) { :asc }
  let(:blanks) { :first }
  let(:klass) { described_class.new(on: on, dir: dir, blanks: blanks) }
  let(:rows) do
    [
      {id: "1"},
      {id: "10"},
      {id: "11"},
      {id: "100"},
      {id: nil},
      {id: ""},
      {id: "XR3"},
      {id: "25"}
    ]
  end

  describe "#call" do
    let(:result) { klass.call(rows).map { |row| row[:id] } }

    context "with asc, as string, blanks first" do
      it "sorts as expected" do
        expect(result).to eq([nil, "", "1", "10", "100", "11", "25", "XR3"])
      end
    end

    context "with asc, as integer, blanks first" do
      let(:klass) do
        described_class.new(on: on, dir: dir, blanks: blanks, as: :to_i)
      end

      it "sorts as expected" do
        expect(result).to eq([nil, "", "1", "10", "11", "25", "100", "XR3"])
      end
    end

    context "with asc, as string, blanks last" do
      let(:blanks) { :last }

      it "sorts as expected" do
        expect(result).to eq(["1", "10", "100", "11", "25", "XR3", nil, ""])
      end
    end

    context "with desc, as string, blanks first" do
      let(:dir) { :desc }

      it "sorts as expected" do
        expect(result).to eq([nil, "", "XR3", "25", "11", "100", "10", "1"])
      end
    end

    context "with missing sortfield" do
      let(:on) { :foo }

      it "raises error" do
        msg = "Cannot sort on missing field: `foo`"
        expect do
          result
        end.to raise_error(
          Kiba::Extend::Utils::Lookup::RowSorter::MissingSortFieldError
        ).with_message(msg)
      end
    end
  end
end
