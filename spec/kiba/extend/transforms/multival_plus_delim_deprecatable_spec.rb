# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Transforms::MultivalPlusDelimDeprecatable do
  class Xform
    include Kiba::Extend::Transforms::MultivalPlusDelimDeprecatable

    attr_reader :multival

    def initialize(multival: omitted = true)
      @multival = set_multival(multival, omitted, self)
    end
  end

  subject(:mod) { Xform.new(**params) }

  context "with no multival" do
    let(:params) { {} }

    it "returns expected" do
      expect(mod.multival).to be false
      expect(mod).not_to receive(:warn)
    end
  end

  context "with multival: true" do
    let(:params) { {multival: true} }
    let(:body) do
      class Warner
        include Kiba::Extend::Transforms::MultivalPlusDelimDeprecatable
      end

      "#{Warner.new.send(:warning_body)}\n"
    end
    let(:warning) { "#{Kiba::Extend.warning_label}:\n  Xform: #{body}" }

    it "returns expected" do
      expect(mod.multival).to be true
    end

    it "warns" do
      expect { mod }.to output(warning).to_stderr
    end
  end

  context "with multival: false" do
    let(:params) { {multival: false} }
    let(:body) do
      class Warner
        include Kiba::Extend::Transforms::MultivalPlusDelimDeprecatable
      end

      "#{Warner.new.send(:warning_body)}\n"
    end
    let(:warning) { "#{Kiba::Extend.warning_label}:\n  Xform: #{body}" }

    it "returns expected" do
      expect(mod.multival).to be false
    end

    it "warns" do
      expect { mod }.to output(warning).to_stderr
    end
  end

  context "when default multival value = true" do
    before do
      class Xform
        def multival_default
          true
        end
      end
    end
    after do
      mod.class.remove_method(:multival_default)
    end

    context "with no multival" do
      let(:params) { {} }

      it "returns expected" do
        expect(mod.multival).to be true
        expect(mod).not_to receive(:warn)
      end
    end
  end
end
