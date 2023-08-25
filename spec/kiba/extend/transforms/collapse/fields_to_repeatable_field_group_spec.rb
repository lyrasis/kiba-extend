# frozen_string_literal: true

require "spec_helper"

# rubocop:todo Layout/LineLength
RSpec.describe Kiba::Extend::Transforms::Collapse::FieldsToRepeatableFieldGroup do
  # rubocop:enable Layout/LineLength
  subject(:xform) { described_class.new(**params) }
  let(:params) { {sources: sources, targets: targets, delim: delim} }
  let(:sources) { %i[a b] }
  let(:targets) { %i[foo bar] }
  let(:delim) { "|" }
  let(:result) { input.map { |row| xform.process(row) } }

  let(:input) do
    [
      {a_foo: "afoo", a_bar: "abar", b_foo: "bfoo", b_bar: "bbar"},
      {a_foo: "afoo", a_bar: "abar", b_foo: nil, b_bar: ""},
      {a_foo: "afoo", a_bar: "abar", b_foo: nil, b_bar: "%NULLVALUE%"},
      {a_foo: "afoo", a_bar: "%NULLVALUE%", b_foo: "%NULLVALUE%",
       b_bar: "bbar"},
      {a_foo: nil, a_bar: nil, b_foo: nil, b_bar: ""},
      {a_foo: "afoo", a_bar: "abar", b_foo: "bfoo"}
    ]
  end

  context "with empty_groups: :delete" do
    let(:expected) do
      [
        {foo: "afoo|bfoo", bar: "abar|bbar"},
        {foo: "afoo", bar: "abar"},
        {foo: "afoo", bar: "abar"},
        {foo: "afoo|%NULLVALUE%", bar: "%NULLVALUE%|bbar"},
        {foo: nil, bar: nil},
        {foo: "afoo|bfoo", bar: "abar|%NULLVALUE%"}
      ]
    end

    it "transforms as expected" do
      expect(result).to eq(expected)
    end
  end

  context "with empty_groups: :retain" do
    let(:params) {
      {sources: sources, targets: targets, delim: delim, empty_groups: :retain}
    }
    let(:expected) do
      [
        {foo: "afoo|bfoo", bar: "abar|bbar"},
        {foo: "afoo|%NULLVALUE%", bar: "abar|%NULLVALUE%"},
        {foo: "afoo|%NULLVALUE%", bar: "abar|%NULLVALUE%"},
        {foo: "afoo|%NULLVALUE%", bar: "%NULLVALUE%|bbar"},
        {foo: nil, bar: nil},
        {foo: "afoo|bfoo", bar: "abar|%NULLVALUE%"}
      ]
    end

    it "transforms as expected" do
      expect(result).to eq(expected)
    end
  end

  # rubocop:todo Layout/LineLength
  context "with uneven fields and default enforce_evenness (true) and default empty_groups (:delete)" do
    # rubocop:enable Layout/LineLength
    let(:sources) { %i[a b c d e] }
    let(:input) do
      [
        {
          a_foo: "a|f", a_bar: "a",
          b_foo: "bf", b_bar: "b",
          c_foo: "", c_bar: "c",
          d_foo: "d|", d_bar: nil
        }
      ]
    end
    let(:expected) do
      [{
        foo: "a|f|bf|%NULLVALUE%|d",
        bar: "a|%NULLVALUE%|b|c|%NULLVALUE%"
      }]
    end

    it "transforms as expected" do
      expect(result).to eq(expected)
    end

    context "with custom null_placeholder (and custom even_val: :value)" do
      let(:params) {
        # rubocop:todo Layout/LineLength
        {sources: sources, targets: targets, delim: delim, null_placeholder: "BLANK",
         # rubocop:enable Layout/LineLength
         even_val: :value}
      }
      let(:expected) do
        [
          {
            foo: "a|f|bf|BLANK|d",
            bar: "a|a|b|c|BLANK"
          }
        ]
      end

      it "transforms as expected" do
        expect(result).to eq(expected)
      end
    end

    context "with custom null_placeholder (and default even_val)" do
      let(:params) {
        {sources: sources, targets: targets, delim: delim,
         null_placeholder: "BLANK"}
      }
      let(:expected) do
        [
          {
            foo: "a|f|bf|BLANK|d",
            bar: "a|%NULLVALUE%|b|c|BLANK"
          }
        ]
      end

      it "transforms as expected" do
        expect(result).to eq(expected)
      end
    end

    context "with custom null_placeholder (and custom even_val: EVENED)" do
      let(:params) {
        # rubocop:todo Layout/LineLength
        {sources: sources, targets: targets, delim: delim, null_placeholder: "BLANK",
         # rubocop:enable Layout/LineLength
         even_val: "EVENED"}
      }
      let(:expected) do
        [
          {
            foo: "a|f|bf|BLANK|d",
            bar: "a|EVENED|b|c|BLANK"
          }
        ]
      end

      it "transforms as expected" do
        expect(result).to eq(expected)
      end
    end
  end

  # rubocop:todo Layout/LineLength
  context "with uneven fields and default enforce_evenness (true) and empty_groups = :retain" do
    # rubocop:enable Layout/LineLength
    let(:sources) { %i[a b c d e] }
    let(:params) {
      {sources: sources, targets: targets, delim: delim, empty_groups: :retain}
    }
    let(:input) do
      [{
        a_foo: "a|f", a_bar: "a",
        b_foo: "bf", b_bar: "b",
        c_foo: "", c_bar: "c",
        d_foo: "d|", d_bar: nil
      }]
    end
    let(:expected) do
      [{
        foo: "a|f|bf|%NULLVALUE%|d|%NULLVALUE%|%NULLVALUE%",
        bar: "a|%NULLVALUE%|b|c|%NULLVALUE%|%NULLVALUE%|%NULLVALUE%"
      }]
    end

    it "transforms as expected" do
      expect(result).to eq(expected)
    end
  end

  # rubocop:todo Layout/LineLength
  context "with uneven fields and enforce_evenness: false and default empty_groups (:delete)" do
    # rubocop:enable Layout/LineLength
    let(:sources) { %i[a b c d] }
    let(:params) {
      {sources: sources, targets: targets, delim: delim,
       enforce_evenness: false}
    }
    let(:input) do
      [
        {
          a_foo: "a|f", a_bar: "a",
          b_foo: "bf", b_bar: "b",
          c_foo: "", c_bar: "c",
          d_foo: "d|", d_bar: nil
        }
      ]
    end
    let(:expected) do
      [
        {
          foo: "a|f|bf|%NULLVALUE%|d|%NULLVALUE%",
          bar: "a|b|c|%NULLVALUE%"
        }
      ]
    end

    it "transforms as expected" do
      expect(result).to eq(expected)
    end
  end
end
