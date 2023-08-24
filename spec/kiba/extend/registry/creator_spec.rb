# frozen_string_literal: true

require "spec_helper"

# used to test creator validation below
module Helpers
  module Project
    module Jobby
      module_function

      def job
        "run!"
      end
    end

    module Unjobby
      module_function

      def prep
        "prepped"
      end
    end

    module JobbyArg
      module_function

      def job(shout: false)
        val = "run!"
        shout ? val.upcase : val
      end
    end

    module UnjobbyArg
      module_function

      def prep(shout: false)
        val = "prepped"
        shout ? val.upcase : val
      end
    end
  end
end

# rubocop:disable Metrics/BlockLength
RSpec.describe "Kiba::Extend::Registry::Creator" do
  let(:creator) { Kiba::Extend::Registry::Creator.new(spec) }

  context "with non-method creator" do
    context "when a String" do
      let(:spec) { "a string" }
      it "raises error" do
        msg = "Registry::Creator cannot be called with String (a string)"
        expect {
          creator
        }.to raise_error(Kiba::Extend::Registry::Creator::TypeError, msg)
      end
    end

    context "when a Method" do
      let(:spec) { Helpers::Project::Unjobby.method(:prep) }
      it "sets mod and meth", :aggregate_failures do
        expect(creator.meth).to eq(:prep)
        expect(creator.mod).to eq(Helpers::Project::Unjobby)
      end
    end

    context "when a Module not containing a `job` method, and no method given" do
      let(:spec) { Helpers::Project::Unjobby }
      it "raises error" do
        msg = "Helpers::Project::Unjobby passed as Registry::Creator, but does not define `job` method"
        expect {
          creator
        }.to raise_error(
          Kiba::Extend::Registry::Creator::JoblessModuleCreatorError, msg
        )
      end
    end

    context "when a Module containing a `job` method, and no method given" do
      let(:spec) { Helpers::Project::Jobby }
      it "sets mod and meth", :aggregate_failures do
        expect(creator.meth).to eq(:job)
        expect(creator.mod).to eq(Helpers::Project::Jobby)
      end
    end

    context "when Hash" do
      context "with missing required key" do
        let(:spec) { {args: {shout: true}} }

        it "raises error" do
          msg = "Registry::Creator passed Hash with no `callee` key"
          expect {
            creator
          }.to raise_error(Kiba::Extend::Registry::Creator::HashCreatorKeyError,
            msg)
        end
      end

      context "with callee that is not a Method or Module" do
        let(:spec) { {callee: "a string"} }

        it "raises error" do
          msg = "Registry::Creator passed Hash with String `callee`. Give Method or Module instead."
          expect {
            creator
          }.to raise_error(
            Kiba::Extend::Registry::Creator::HashCreatorCalleeError, msg
          )
        end
      end

      context "with args that is not a Hash" do
        let(:spec) {
          {callee: Helpers::Project::JobbyArg, args: "another string"}
        }

        it "raises error" do
          msg = "Registry::Creator passed Hash with String `args`. Give a Hash instead."
          expect {
            creator
          }.to raise_error(
            Kiba::Extend::Registry::Creator::HashCreatorArgsTypeError, msg
          )
        end
      end

      context "with good callee and args" do
        let(:spec) {
          {callee: Helpers::Project::JobbyArg, args: {shout: true}}
        }

        it "sets instance vars as expected", :aggregate_failures do
          expect(creator.mod).to eq(Helpers::Project::JobbyArg)
          expect(creator.meth).to eq(:job)
          expect(creator.args).to eq({shout: true})
        end
      end
    end
  end

  describe "#call" do
    let(:result) { creator.call }

    context "with no args" do
      context "with method" do
        let(:spec) { Helpers::Project::Unjobby.method(:prep) }

        it "calls as expected" do
          expect(result).to eq("prepped")
        end
      end

      context "with jobby module" do
        let(:spec) { Helpers::Project::Jobby }

        it "calls as expected" do
          expect(result).to eq("run!")
        end
      end
    end

    context "with args" do
      context "with method" do
        let(:spec) {
          {callee: Helpers::Project::UnjobbyArg.method(:prep),
           args: {shout: true}}
        }

        it "calls as expected" do
          expect(result).to eq("PREPPED")
        end
      end

      context "with jobby module" do
        let(:spec) { {callee: Helpers::Project::JobbyArg, args: {shout: true}} }

        it "calls as expected" do
          expect(result).to eq("RUN!")
        end
      end
    end
  end

  describe "#to_s" do
    let(:result) { creator.to_s }
    context "without args" do
      let(:spec) { Helpers::Project::JobbyArg }

      it "returns expected string" do
        expect(result).to eq("Helpers::Project::JobbyArg.job")
      end
    end

    context "with args" do
      let(:spec) {
        {callee: Helpers::Project::JobbyArg, args: {shout: true, volume: 23}}
      }

      it "returns expected string" do
        expect(result).to eq("Helpers::Project::JobbyArg.job(shout: true, volume: 23)")
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
