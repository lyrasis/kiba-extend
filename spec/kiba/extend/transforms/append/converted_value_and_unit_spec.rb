# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Transforms::Append::ConvertedValueAndUnit do
  let(:accumulator) { [] }
  let(:test_job) {
    Helpers::TestJob.new(input: input, accumulator: accumulator,
      transforms: transforms)
  }
  let(:result) { test_job.accumulator }

  let(:input) do
    [
      {value: nil, unit: nil},
      {value: "1.5", unit: nil},
      {value: "1.5", unit: "inches"},
      {value: "1.5", unit: "in."},
      {value: "5", unit: "centimeters"},
      {value: "2", unit: "feet"},
      {value: "2", unit: "meters"},
      {value: "2", unit: "pounds"},
      {value: "2", unit: "kilograms"},
      {value: "2", unit: "ounces"},
      {value: "200", unit: "grams"}
    ]
  end

  let(:transforms) do
    Kiba.job_segment do
      transform Append::ConvertedValueAndUnit, value: :value, unit: :unit,
        delim: "|", places: 2
    end
  end

  let(:expected) do
    [
      {value: nil, unit: nil},
      {value: "1.5", unit: nil},
      {value: "1.5|3.81", unit: "inches|centimeters"},
      {value: "1.5|3.81", unit: "in.|centimeters"},
      {value: "5|1.97", unit: "centimeters|inches"},
      {value: "2|0.61", unit: "feet|meters"},
      {value: "2|6.56", unit: "meters|feet"},
      {value: "2|0.91", unit: "pounds|kilograms"},
      {value: "2|4.41", unit: "kilograms|pounds"},
      {value: "2|56.7", unit: "ounces|grams"},
      {value: "200|7.05", unit: "grams|ounces"}
    ]
  end

  it "adds converted value and unit" do
    expect(result).to eq(expected)
  end

  context "when value or unit is multivalued" do
    let(:input) do
      [
        {value: "12|1", unit: "inches|feet"},
        {value: "12|1", unit: "inches"},
        {value: "12", unit: "inches|feet"}
      ]
    end

    let(:expected) do
      [
        {value: "12|1", unit: "inches|feet"},
        {value: "12|1", unit: "inches"},
        {value: "12", unit: "inches|feet"}
      ]
    end

    it "returns original rows" do
      expect(result).to eq(expected)
    end
  end

  context "when value contains string fraction" do
    let(:input) do
      [
        {value: "1 1/2", unit: "inches"}
      ]
    end

    let(:expected) do
      [
        {value: "1 1/2", unit: "inches"}
      ]
    end

    it "returns original rows" do
      expect(result).to eq(expected)
    end
  end

  context "when unit alias known by Measured is given and conversion customized" do
    let(:input) do
      [
        {value: "36", unit: "in."}
      ]
    end

    let(:transforms) do
      Kiba.job_segment do
        transform Append::ConvertedValueAndUnit,
          value: :value,
          unit: :unit,
          delim: "|",
          places: 2,
          conversions: {"inches" => "feet"}
      end
    end

    let(:expected) do
      [
        {value: "36|3", unit: "in.|feet"}
      ]
    end

    it "adds value and unit without requiring custom parameters" do
      expect(result).to eq(expected)
    end
  end

  context "when default conversion is overridden" do
    let(:input) do
      [
        {value: "36", unit: "inches"}
      ]
    end

    let(:transforms) do
      Kiba.job_segment do
        transform Append::ConvertedValueAndUnit,
          value: :value,
          unit: :unit,
          delim: "|",
          places: 2,
          conversions: {"inches" => "feet"}
      end
    end

    let(:expected) do
      [
        {value: "36|3", unit: "inches|feet"}
      ]
    end

    it "adds value and unit" do
      expect(result).to eq(expected)
    end
  end

  context "when default converted unit name is overridden" do
    let(:input) do
      [
        {value: "36", unit: "inches"}
      ]
    end

    let(:transforms) do
      Kiba.job_segment do
        transform Append::ConvertedValueAndUnit,
          value: :value,
          unit: :unit,
          delim: "|",
          places: 2,
          unit_names: {"centimeters" => "cm"}
      end
    end

    let(:expected) do
      [
        {value: "36|91.44", unit: "inches|cm"}
      ]
    end

    it "adds value and unit" do
      expect(result).to eq(expected)
    end
  end

  context "when using Measured unit not configured for transform" do
    let(:input) do
      [
        {value: "1", unit: "yard"},
        {value: "36", unit: "inches"}
      ]
    end

    let(:transforms) do
      Kiba.job_segment do
        transform Append::ConvertedValueAndUnit,
          value: :value,
          unit: :unit,
          delim: "|",
          places: 2,
          conversions: {"inches" => "yards", "yards" => "feet"}
      end
    end

    let(:expected) do
      [
        {value: "1|3", unit: "yard|feet"},
        {value: "36|1", unit: "inches|yd"}
      ]
    end

    it "adds value and unit" do
      expect(result).to eq(expected)
    end
  end

  context "when unit conversion is unknown" do
    let(:input) do
      [
        {value: "1", unit: "yard"}
      ]
    end

    let(:transforms) do
      Kiba.job_segment do
        transform Append::ConvertedValueAndUnit,
          value: :value,
          unit: :unit,
          delim: "|",
          places: 2
      end
    end

    let(:expected) do
      [
        {value: "1", unit: "yard"}
      ]
    end

    it "returns original row" do
      expect(result).to eq(expected)
    end

    it "prints warning to STDOUT" do
      msg = %(KIBA WARNING: Unknown conversion to perform for "yard" in "unit" field. Configure conversions parameter\n)
      expect { result }.to output(msg).to_stdout
    end
  end

  context "when unit conversion is unconvertable" do
    let(:input) do
      [
        {value: "2", unit: "inches"}
      ]
    end

    let(:transforms) do
      Kiba.job_segment do
        transform Append::ConvertedValueAndUnit,
          value: :value,
          unit: :unit,
          delim: "|",
          places: 2,
          conversions: {"inches" => "grams"}
      end
    end

    let(:expected) do
      [
        {value: "2", unit: "inches"}
      ]
    end

    it "returns original row" do
      expect(result).to eq(expected)
    end

    it "prints warning to STDOUT" do
      msg = %(KIBA WARNING: "inches" cannot be converted to "grams". Check your conversions parameter or configure a custom conversion_amounts parameter\n)
      expect { result }.to output(msg).to_stdout
    end
  end

  context "when unknown unit not configured" do
    let(:input) do
      [
        {value: "1", unit: "step"}
      ]
    end

    let(:transforms) do
      Kiba.job_segment do
        transform Append::ConvertedValueAndUnit,
          value: :value,
          unit: :unit,
          delim: "|",
          places: 2,
          conversions: {"step" => "feet"}
      end
    end

    let(:expected) do
      [
        {value: "1", unit: "step"}
      ]
    end

    it "returns original row" do
      expect(result).to eq(expected)
    end

    it "prints warning to STDOUT" do
      msg = %(KIBA WARNING: Unknown unit "step" in "unit" field. You may need to configure a custom unit. See example 3 in transform documentation\n)
      expect { result }.to output(msg).to_stdout
    end
  end

  context "when custom unit conversion configured" do
    let(:input) do
      [
        {value: "4", unit: "hops"},
        {value: "15", unit: "leaps"}
      ]
    end

    let(:transforms) do
      Kiba.job_segment do
        transform Append::ConvertedValueAndUnit,
          value: :value,
          unit: :unit,
          delim: "|",
          places: 2,
          conversions: {"hops" => "jumps", "leaps" => "hops"},
          conversion_amounts: {
            leaps: [10, :hops],
            hops: [0.25, :jumps]
          }
      end
    end

    let(:expected) do
      [
        {value: "4|1", unit: "hops|jumps"},
        {value: "15|150", unit: "leaps|hops"}
      ]
    end

    it "adds value and unit" do
      expect(result).to eq(expected)
    end
  end
end
