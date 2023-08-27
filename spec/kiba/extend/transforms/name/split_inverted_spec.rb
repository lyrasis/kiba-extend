# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Transforms::Name::SplitInverted do
  let(:klass) { Name::SplitInverted.new(source: :iname) }

  let(:rows) do
    [
      {iname: "Smith, Robert"},
      {iname: "Smith, Robert J."},
      {iname: "Smith-Jones, Robert J."},
      {iname: "Smith, Robert James"},
      {iname: "Smith, R. James"},
      {iname: "Smith, Robert (Bob)"},
      {iname: "Smith, Robert James (Bob)"},
      {iname: "Smith, R. J."},
      {iname: "Smith, R.J."},
      {iname: "Smith, R J"},
      {iname: "Smith, RJ"},
      {iname: "Smith, RJR"},
      {iname: "Smith, RJRR"},
      {iname: "Smith, R."},
      {iname: "Smith"},
      {iname: "Smith, Robert, Jr."},
      {iname: "Smith, R.J., Sr."},
      {iname: "Smith, R. J., Sr."},
      {iname: "R.J. Smith & Co."},
      {iname: "Smith, James, Robert & Co."},
      {iname: 'Robert "Bob" Smith'},
      {iname: ""},
      {iname: nil},
      {foo: "bar"}
    ]
  end

  let(:expected) do
    [
      {iname: "Smith, Robert", firstname: "Robert", lastname: "Smith",
       middlename: nil, suffix: nil},
      {iname: "Smith, Robert J.", firstname: "Robert", lastname: "Smith",
       middlename: "J.", suffix: nil},
      {iname: "Smith-Jones, Robert J.", firstname: "Robert",
       lastname: "Smith-Jones", middlename: "J.", suffix: nil},
      {iname: "Smith, Robert James", firstname: "Robert", lastname: "Smith",
       middlename: "James", suffix: nil},
      {iname: "Smith, R. James", firstname: "R.", lastname: "Smith",
       middlename: "James", suffix: nil},
      {iname: "Smith, Robert (Bob)", firstname: "Robert", lastname: "Smith",
       middlename: "(Bob)", suffix: nil},
      {iname: "Smith, Robert James (Bob)", firstname: "Robert",
       lastname: "Smith", middlename: "James (Bob)", suffix: nil},
      {iname: "Smith, R. J.", firstname: "R.", lastname: "Smith",
       middlename: "J.", suffix: nil},
      {iname: "Smith, R.J.", firstname: "R.", lastname: "Smith",
       middlename: "J.", suffix: nil},
      {iname: "Smith, R J", firstname: "R", lastname: "Smith", middlename: "J",
       suffix: nil},
      {iname: "Smith, RJ", firstname: "R", lastname: "Smith", middlename: "J",
       suffix: nil},
      {iname: "Smith, RJR", firstname: "R", lastname: "Smith",
       middlename: "JR", suffix: nil},
      {iname: "Smith, RJRR", firstname: "RJRR", lastname: "Smith",
       middlename: nil, suffix: nil},
      {iname: "Smith, R.", firstname: "R.", lastname: "Smith", middlename: nil,
       suffix: nil},
      {iname: "Smith", firstname: nil, lastname: nil, middlename: nil,
       suffix: nil},
      {iname: "Smith, Robert, Jr.", firstname: "Robert", lastname: "Smith",
       middlename: nil, suffix: "Jr."},
      {iname: "Smith, R.J., Sr.", firstname: "R.", lastname: "Smith",
       middlename: "J.", suffix: "Sr."},
      {iname: "Smith, R. J., Sr.", firstname: "R.", lastname: "Smith",
       middlename: "J.", suffix: "Sr."},
      {iname: "R.J. Smith & Co.", firstname: nil, lastname: nil,
       middlename: nil, suffix: nil},
      {iname: "Smith, James, Robert & Co.", firstname: "James",
       lastname: "Smith", middlename: nil, suffix: "Robert & Co."},
      {iname: 'Robert "Bob" Smith', firstname: nil, lastname: nil,
       middlename: nil, suffix: nil},
      {iname: "", firstname: nil, lastname: nil, middlename: nil, suffix: nil},
      {iname: nil, firstname: nil, lastname: nil, middlename: nil, suffix: nil},
      {foo: "bar", firstname: nil, lastname: nil, middlename: nil, suffix: nil}

    ]
  end

  let(:result) { rows.map { |row| klass.process(row) } }

  context "with default settings" do
    it "transforms as expected" do
      expect(result).to eq(expected)
    end
  end

  context "with custom targets" do
    let(:klass) do
      Name::SplitInverted.new(source: :iname, targets: %i[f m l s])
    end
    let(:row) { {iname: "Smith, R.J., Sr."} }
    let(:expected) do
      {iname: "Smith, R.J., Sr.", f: "R.", l: "Smith", m: "J.", s: "Sr."}
    end

    it "transforms as expected" do
      puts expected
      expect(klass.process(row)).to eq(expected)
    end
  end

  context "with custom fallback" do
    let(:klass) { Name::SplitInverted.new(source: :iname, fallback: :lastname) }
    let(:row) { {iname: "Smith"} }
    let(:expected) do
      {iname: "Smith", firstname: nil, lastname: "Smith", middlename: nil,
       suffix: nil}
    end

    it "transforms as expected" do
      puts expected
      expect(klass.process(row)).to eq(expected)
    end
  end

  context "with bad fallback value" do
    let(:klass) { Name::SplitInverted.new(source: :iname, fallback: :surname) }

    it "raises error" do
      msg = "fallback must equal :all_nil or one of the target field names"
      expect { klass }.to raise_error(ArgumentError, msg)
    end
  end
end
