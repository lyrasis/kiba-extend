# frozen_string_literal: true

require "spec_helper"

# used to test creator validation below
module Helpers
  module Project
    class FakeJob
      attr_reader :args

      def initialize(args = {})
        @args = args
      end

      def run = nil
    end

    module Jobby
      module_function

      def job = FakeJob.new
    end

    module Unjobby
      module_function

      def prep = FakeJob.new
    end

    module JobbyArg
      module_function

      def job(args) = FakeJob.new(**args)
      # def job(shout: false)
      #   val = "run!"
      #   shout ? val.upcase : val
      # end
    end

    module UnjobbyArg
      module_function

      def prep(args) = FakeJob.new(**args)
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
        expect do
          creator
        end.to raise_error(Kiba::Extend::Registry::Creator::TypeError, msg)
      end
    end

    context "when a Method" do
      let(:spec) { Helpers::Project::Unjobby.method(:prep) }
      it "sets mod and meth", :aggregate_failures do
        expect(creator.meth).to eq(:prep)
        expect(creator.mod).to eq(Helpers::Project::Unjobby)
      end
    end

    context "when a Module has no `job` method, and no method given" do
      let(:spec) { Helpers::Project::Unjobby }
      it "raises error" do
        msg = "Helpers::Project::Unjobby passed as Registry::Creator, but "\
          "does not define `job` method"
        expect do
          creator
        end.to raise_error(
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
          expect do
            creator
          end.to raise_error(
            Kiba::Extend::Registry::Creator::HashCreatorKeyError,
            msg
          )
        end
      end

      context "with callee that is not a Method or Module" do
        let(:spec) { {callee: "a string"} }

        it "raises error" do
          msg = "Registry::Creator passed Hash with String `callee`. Give "\
            "Method or Module instead."
          expect do
            creator
          end.to raise_error(
            Kiba::Extend::Registry::Creator::HashCreatorCalleeError, msg
          )
        end
      end

      context "with args that is not a Hash" do
        let(:spec) do
          {callee: Helpers::Project::JobbyArg, args: "another string"}
        end

        it "raises error" do
          msg = "Registry::Creator passed Hash with String `args`. Give a "\
            "Hash instead."
          expect do
            creator
          end.to raise_error(
            Kiba::Extend::Registry::Creator::HashCreatorArgsTypeError, msg
          )
        end
      end

      context "with good callee and args" do
        let(:spec) do
          {callee: Helpers::Project::JobbyArg, args: {shout: true}}
        end

        it "sets instance vars as expected", :aggregate_failures do
          expect(creator.mod).to eq(Helpers::Project::JobbyArg)
          expect(creator.meth).to eq(:job)
          expect(creator.args).to eq({shout: true})
        end
      end
    end
  end

  describe "#call" do
    context "with no args" do
      context "with method" do
        it "calls as expected" do
          unjobby = class_double(Helpers::Project::Unjobby)
          expect(unjobby).to receive(:prep)
            .and_return(Helpers::Project::FakeJob.new)
          c = Kiba::Extend::Registry::Creator.new(unjobby.method(:prep))
          result = c.call
          expect(result).to be_a(Helpers::Project::FakeJob)
        end
      end

      context "with jobby module" do
        it "calls as expected" do
          expect(Helpers::Project::Jobby).to receive(:job)
            .and_return(Helpers::Project::FakeJob.new)
          c = Kiba::Extend::Registry::Creator.new(Helpers::Project::Jobby)
          result = c.call
          expect(result).to be_a(Helpers::Project::FakeJob)
        end
      end
    end

    context "with args" do
      context "with method" do
        it "calls as expected" do
          args = {shout: true}
          spec = {callee: Helpers::Project::UnjobbyArg.method(:prep),
                  args: args}
          expect(Helpers::Project::UnjobbyArg).to receive(:prep)
            .and_return(Helpers::Project::FakeJob.new(**args))
          c = Kiba::Extend::Registry::Creator.new(spec)
          result = c.call
          expect(result).to be_a(Helpers::Project::FakeJob)
          expect(result.args[:shout]).to be true
        end
      end

      context "with jobby module" do
        it "calls as expected" do
          args = {shout: true}
          spec = {callee: Helpers::Project::JobbyArg,
                  args: args}
          expect(Helpers::Project::JobbyArg).to receive(:job)
            .and_return(Helpers::Project::FakeJob.new(**args))
          c = Kiba::Extend::Registry::Creator.new(spec)
          result = c.call
          expect(result).to be_a(Helpers::Project::FakeJob)
          expect(result.args[:shout]).to be true
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
      let(:spec) do
        {callee: Helpers::Project::JobbyArg, args: {shout: true, volume: 23}}
      end

      it "returns expected string" do
        msg = "Helpers::Project::JobbyArg.job(shout: true, volume: 23)"
        expect(result).to eq(msg)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
