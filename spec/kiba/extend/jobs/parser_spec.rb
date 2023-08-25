# frozen_string_literal: true

require "spec_helper"

# rubocop:disable Metrics/BlockLength

class ParserClass
  include Kiba::Extend::Jobs::Parser
end

RSpec.describe "Kiba::Extend::Jobs::Parser" do
  #  let(:src_file){ File.join(fixtures_dir, 'base_job_dest.csv') }
  let(:control) { Kiba::Control.new }
  let(:context) { Kiba::Context.new(control) }
  let(:sources) do
    [{klass: Kiba::Common::Sources::CSV,
      # rubocop:todo Layout/LineLength
      args: {filename: "/Users/kristina/data/fabric_workshop/migration/fwm/objects.csv",
             # rubocop:enable Layout/LineLength
             # rubocop:todo Layout/LineLength
             csv_options: {headers: true, header_converters: [:symbol, :downcase],
                           # rubocop:enable Layout/LineLength
                           converters: [:stripplus]}}}]
  end
  let(:srcstrs) do
    sources.map { |src| "source #{src[:klass]}, **#{src[:args]}" }.join("\n")
  end

  let(:transforms) do
    Kiba.job_segment do
      transform Kiba::Extend::Transforms::Rename::Field, from: :letter,
        to: :alpha
    end
  end
  let(:parser) { ParserClass.new }
  let(:result) { parser.parse_job(control, context, segments) }

  context "with transforms" do
    let(:segments) { [transforms] }
    let(:expected) do
      [{klass: Kiba::Extend::Transforms::Rename::Field,
        args: [{from: :letter, to: :alpha}],
        block: nil}]
    end
    it "returns expected Kiba::Control" do
      expect(result.transforms).to eq(expected)
    end
  end
end
# rubocop:enable Metrics/BlockLength
