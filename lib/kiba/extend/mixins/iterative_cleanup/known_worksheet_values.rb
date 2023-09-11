# frozen_string_literal: true

require "csv"
require "set"

module Kiba::Extend::Mixins::IterativeCleanup
  class KnownWorksheetValues
    def initialize(mod)
      @mod = mod
      @field = mod.collated_orig_values_id_field
        .to_s
      @values = nil
    end

    def call
      return values if values

      @values = Set.new
      mod.provided_worksheets.each { |file| extract_values(file) }
      values
    end

    private

    attr_reader :mod, :field, :values

    def extract_values(file)
      CSV.foreach(file, headers: true) do |row|
        vals = row[field]
        next if vals.blank?

        vals.split(mod.collation_delim).each do |val|
          values << val
        end
      end
    end
  end
end
