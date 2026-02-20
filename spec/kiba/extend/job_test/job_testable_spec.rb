# frozen_string_literal: true

require "spec_helper"

class JobTestClass
  include Kiba::Extend::JobTest::JobTestable

  def initialize(config)
    initialization_logic(config)
  end
end

RSpec.describe Kiba::Extend::JobTest::JobTestable do
  subject(:test) { JobTestClass.new(config) }

  context "with invalid key" do
    let(:config) { {path: "p", b: "bog", c?: false} }

    it "fails to initialize" do
      expect { test }.to raise_error(/: c\?/)
    end
  end

  context "with path key in config" do
    let(:config) { {b: "bog", c: false} }

    it "fails to initialize" do
      expect { test }.to raise_error(/requires a :path key/)
    end
  end

  context "with valid keys" do
    let(:config) { {path: "p", b: "bog", c: false} }
    it "sets instance variables dynamically" do
      expect(test.instance_variables).to include(:@path, :@b, :@c)
    end

    it "sets attr_reader methods dynamically" do
      expect(test.b).to eq("bog")
      expect(test.c).to be false
    end
  end
end
