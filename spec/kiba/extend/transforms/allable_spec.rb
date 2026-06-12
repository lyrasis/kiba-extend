# frozen_string_literal: true

require "spec_helper"

class AllFields
  attr_reader :fields

  include Allable

  def initialize(fields:)
    @fields = [fields].flatten
  end

  def call(row)
    finalize_fields(row) unless fields_set
  end
end

class AllExcept
  attr_reader :fields, :omit_from_all_fields

  include Allable

  def initialize(fields:, omit_from_all_fields: [])
    @fields = [fields].flatten
    @omit_from_all_fields = omit_from_all_fields
  end

  def call(row)
    finalize_fields(row) unless fields_set
  end
end

RSpec.describe Kiba::Extend::Transforms::Allable do
  context "with :all given as fields value and no field name is :all" do
    it "sets fields as expected" do
      klass = AllFields.new(fields: :all)
      row = {a: "a", b: "b", c: "c"}
      klass.call(row)
      expect(klass.fields).to eq(%i[a b c])
    end
  end

  context "with :all given as fields value and a field name is :all" do
    it "sets fields as expected" do
      klass = AllFields.new(fields: :all)
      row = {a: "a", b: "b", c: "c", all: "all"}
      klass.call(row)
      expect(klass.fields).to eq(%i[all])
    end
  end

  context "with omit_from_all_fields value given" do
    it "sets fields as expected" do
      klass = AllExcept.new(fields: :all, omit_from_all_fields: %i[b])
      row = {a: "a", b: "b", c: "c"}
      klass.call(row)
      expect(klass.fields).to eq(%i[a c])
    end
  end
end
