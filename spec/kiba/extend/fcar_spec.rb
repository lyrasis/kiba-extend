# frozen_string_literal: true

require "spec_helper"

module Kiba::Extend::TestConfig
  module Apple
    def self.config = true

    def self.provided_worksheets = []

    def self.merge_job = :apple__merge
  end

  module Orange
    def self.config = true

    def self.provided_worksheets = []

    def self.merge_job = :orange__merge
  end

  module Cherry
    def self.config = true

    def self.provided_worksheets = []

    def self.merge_job = :cherry__merge
  end
end

RSpec.describe Kiba::Extend::Fcar do
  subject(:mod) { described_class }

  before do
    Kiba::Extend.config.config_namespaces << Kiba::Extend::TestConfig
    Kiba::Extend::Fcar.config.chute = %w[
      Apple
      Orange
      Cherry
    ]
    Kiba::Extend::Fcar.config.base_source = :base__source
  end
  after(:each) { Kiba::Extend::Fcar.reset_config }

  it "returns as expected" do
    expect(mod.processes).to eq([])
    expect do
      mod.previous_merged(Kiba::Extend::TestConfig::Orange)
    end.to raise_error(Kiba::Extend::UnknownFcarConfigError)
    expect(mod.final_merged).to eq(:base__source)
    expect(mod.chute).to eq({
      "Apple" => "",
      "Orange" => "",
      "Cherry" => ""
    })
  end

  context "when Orange is pending" do
    before do
      Kiba::Extend::Fcar.config
        .pending_processes << Kiba::Extend::TestConfig::Orange
    end

    it "returns as expected" do
      expect(mod.processes).to eq([
        Kiba::Extend::TestConfig::Orange
      ])
      expect(
        mod.previous_merged(Kiba::Extend::TestConfig::Orange)
      ).to eq(:base__source)
      expect(mod.final_merged).to eq(:orange__merge)
    end
  end

  # rubocop:disable Lint/ConstantDefinitionInBlock
  context "when Apple is pending and Cherry has worksheet" do
    before do
      Kiba::Extend::Fcar.config
        .pending_processes << Kiba::Extend::TestConfig::Apple
      module Kiba::Extend::TestConfig::Cherry
        def self.provided_worksheets = [:foo]
      end
    end

    after do
      module Kiba::Extend::TestConfig::Cherry
        def self.provided_worksheets = []
      end
    end
    # rubocop:enable Lint/ConstantDefinitionInBlock

    it "returns as expected" do
      expect(mod.processes).to eq([
        Kiba::Extend::TestConfig::Apple,
        Kiba::Extend::TestConfig::Cherry
      ])
      expect(
        mod.previous_merged(Kiba::Extend::TestConfig::Cherry)
      ).to eq(:apple__merge)
      expect(mod.final_merged).to eq(:cherry__merge)
    end
  end

  # rubocop:disable Lint/ConstantDefinitionInBlock
  context "when Apple is pending but lacks :merge_job" do
    before do
      Kiba::Extend::Fcar.config
        .pending_processes << Kiba::Extend::TestConfig::Apple
      module Kiba::Extend::TestConfig::Apple
        class << self
          remove_method(:merge_job)
        end
      end
    end

    after do
      module Kiba::Extend::TestConfig::Apple
        def self.merge_job = :apple__merge
      end
    end
    # rubocop:enable Lint/ConstantDefinitionInBlock

    it "raises error" do
      expect { mod.processes }.to raise_error(
        Kiba::Extend::FcarChuteConfigMissingMethodError
      )
    end
  end
end
