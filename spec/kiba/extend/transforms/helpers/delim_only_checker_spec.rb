# frozen_string_literal: true

RSpec.describe Kiba::Extend::Transforms::Helpers::DelimOnlyChecker do
  subject(:checker) { described_class.new(**params) }

  describe "#call" do
    let(:results) do
      expectations.keys.map do |val|
        [val, checker.call(val)]
      end.to_h
    end

    context "with `delim: |, treat_as_null: nil`" do
      let(:params) { {delim: "|", treat_as_null: nil} }
      let(:expectations) do
        {
          "foo|bar" => false,
          "|" => true,
          " | " => true,
          "%NULLVALUE%|%NULLVALUE%" => false,
          "%NULLVALUE%" => false,
          "%NULLVALUE%|blah" => false,
          "" => true,
          nil => true,
          " " => true
        }
      end

      it "returns expected" do
        expect(results).to eq(expectations)
      end
    end

    context "with `delim: |, treat_as_null: nil, blank_result: false`" do
      let(:params) { {delim: "|", treat_as_null: nil, blank_result: false} }
      let(:expectations) do
        {
          # 'foo|bar' => false,
          # '|' => true,
          # ' | ' => true,
          # '%NULLVALUE%|%NULLVALUE%' => false,
          # '%NULLVALUE%' => false,
          # '%NULLVALUE%|blah' => false,
          # '' => false,
          # nil => false,
          " " => false
        }
      end

      it "returns expected" do
        expect(results).to eq(expectations)
      end
    end

    context "with `delim: |, treat_as_null: default nullvalue`" do
      let(:params) { {delim: "|", treat_as_null: Kiba::Extend.nullvalue} }
      let(:expectations) do
        nv = Kiba::Extend.nullvalue
        {
          "foo|bar" => false,
          " | " => true,
          "|" => true,
          "#{nv}|#{nv}" => true,
          " #{nv} |#{nv}" => true,
          nv.to_s => true,
          "#{nv}|blah" => false,
          "" => true,
          nil => true,
          " " => true
        }
      end

      it "returns expected" do
        expect(results).to eq(expectations)
      end
    end

    context "with `delim: |, treat_as_null: array of nullvalues`" do
      let(:params) do
        {delim: "|", treat_as_null: [Kiba::Extend.nullvalue, "NULL"]}
      end
      let(:expectations) do
        nv = Kiba::Extend.nullvalue
        {
          "foo|bar" => false,
          " | " => true,
          "|" => true,
          "#{nv}|#{nv}" => true,
          "NULL|#{nv}" => true,
          " #{nv} |#{nv}" => true,
          " #{nv} |NULL" => true,
          nv.to_s => true,
          "NULL" => true,
          "#{nv}|blah" => false,
          "" => true,
          nil => true,
          " " => true
        }
      end

      it "returns expected" do
        expect(results).to eq(expectations)
      end
    end
  end
end
