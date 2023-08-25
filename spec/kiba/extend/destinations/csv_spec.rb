# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Destinations::CSV do
  before(:all) { @test_filename = "output.csv" }
  let(:testfile) { @test_filename }

  def run_job(input, output)
    job = Kiba.parse do
      source Kiba::Extend::Sources::Enumerable, input
      destination Kiba::Extend::Destinations::CSV, filename: output,
        initial_headers: %i[y z a]
    end

    Kiba.run(job)

    IO.read(output)
  end

  after(:each) { File.delete(@test_filename) if File.exist?(@test_filename) }

  describe "#write" do
    context "when intial headers present" do
      let(:input) do
        [
          {a: "and", y: "yak", z: "zebra"},
          {a: "apple", y: "yarrow", z: "zizia"}
        ]
      end
      let(:expected) do
        "y,z,a\nyak,zebra,and\nyarrow,zizia,apple\n"
      end
      it "produces CSV as expected" do
        expect(run_job(input, testfile)).to eq(expected)
      end
    end

    context "when intial headers specified but not present" do
      let(:input) do
        [
          {a: "and", z: "zebra"},
          {a: "apple", z: "zizia"}
        ]
      end

      let(:expected) do
        "z,a\nzebra,and\nzizia,apple\n"
      end

      it "produces CSV as expected" do
        expect(run_job(input, testfile)).to eq(expected)
      end

      it "writes warning to STDOUT" do
        msg = "Output data does not contain specified initial header: y"
        expect { run_job(input, testfile) }.to output(/#{msg}/).to_stdout
      end
    end
  end

  describe "#fields" do
    let(:input) do
      [
        {a: "and", y: "yak", z: "zebra"},
        {a: "apple", y: "yarrow", z: "zizia"}
      ]
    end
    let(:expected) do
      %i[a y z]
    end
    it "returns fieldnames as expected",
      skip: "cannot make post-run destination load without error" do
      run_job(input, testfile)
      args = [{filename: "output.csv", initial_headers: [:y, :z]}]
      dest = Kiba::StreamingRunner.to_instance(
        Kiba::Extend::Destinations::CSV, args, nil, false, true
      )
      expect(dest.fields).to eq(expected)
    end
  end
end
