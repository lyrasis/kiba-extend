# frozen_string_literal: true

RSpec.describe Kiba::Extend::Transforms::Helpers::PersonNameChecker do
  subject(:checker) { described_class.new(**params) }

  describe "#call" do
    let(:results) { vals.keys.map { |val| [val, checker.call(val)] }.to_h }
    let(:params) { {} }

    context "with default params" do
      let(:vals) do
        {
          "Elizabeth I" => false,
          "Mary, Mrs. Abcd" => true,
          "Abcd, M. A." => true,
          "Mary, Abcd" => false,
          "Mary, Abcd Grace" => true,
          "cummings, e.e." => false, # initials are assumed capitalized
          "Taylor family" => false,
          "Abcd and Efg families" => false,
          "Prince (person)" => false
        }
      end

      it "returns expected" do
        expect(results).to eq(vals)
      end
    end

    context "with family_is_person" do
      let(:params) { {family_is_person: true} }
      let(:vals) do
        {
          "Taylor Family" => true,
          "Abcd and Efg families" => true
        }
      end

      it "returns expected" do
        expect(results).to eq(vals)
      end
    end

    context "with added pattern" do
      let(:params) { {added_patterns: [/\(person\)/]} }
      let(:vals) do
        {
          "Prince (person)" => true
        }
      end

      it "returns expected" do
        expect(results).to eq(vals)
      end
    end

    context "with added name_list" do
      let(:params) do
        {name_lists: [File.join(Kiba::Extend.ke_dir, "data",
          "us_names_1880-2022_gt100.txt"),
          File.join(Kiba::Extend.ke_dir, "spec", "support",
            "fixtures", "added_names.txt")]}
      end
      let(:vals) do
        {
          "Mary, Abcd" => true
        }
      end

      it "returns expected" do
        expect(results).to eq(vals)
      end
    end

    context "with lenient mode" do
      let(:params) { {mode: :lenient} }
      let(:vals) do
        {
          "Elizabeth I" => true,
          "Mary, Mrs. Abcd" => true,
          "Abcd, M. A." => false,
          "Mary, Abcd" => true,
          "Mary, Abcd Grace" => true,
          "cummings, e.e." => false, # initials are assumed capitalized
          "Taylor family" => false,
          "Abcd and Efg families" => false,
          "Prince (person)" => true
        }
      end

      it "returns expected" do
        expect(results).to eq(vals)
      end
    end

    context "with direct order" do
      let(:params) { {order: :direct} }
      let(:vals) do
        {
          "Elizabeth I" => true,
          "Mary, Mrs. Abcd" => true,
          "Mrs. Abcd Mary" => true,
          "Abcd, M. A." => false,
          "M. A. Abcd" => true,
          "Mary, Abcd" => true,
          "Abcd Mary" => false,
          "Mary, Abcd Grace" => true,
          "Abcd Grace Mary" => true,
          "cummings, e.e." => false, # initials are assumed capitalized
          "e.e. cummings" => false,
          "Taylor family" => false,
          "Abcd and Efg families" => false,
          "Prince (person)" => true
        }
      end

      it "returns expected" do
        expect(results).to eq(vals)
      end
    end
  end
end
