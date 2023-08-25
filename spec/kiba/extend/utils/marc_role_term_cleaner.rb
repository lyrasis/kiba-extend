# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Utils::MarcRoleTermCleaner do
  subject(:cleaner) { described_class.new }

  describe "#call" do
    it "returns expected" do
      expectations = {
        "publisher." => "publisher",
        "(printer)" => "printer",
        "author," => "author",
        "photographer (work)" => "photographer",
        "photographer (expression)" => "photographer",
        "photographer (manifestation)" => "photographer",
        "photographer (item)" => "photographer",
        "comp" => "compiler",
        "comp. and ed" => "compiler|editor",
        "ed." => "editor",
        "engr." => "engraver",
        "illus" => "illustrator",
        "engravers" => "engraver",
        "architects" => "architect",
        "illustrators" => "illustrator",
        "pbl" => "publisher",
        "publishers" => "publisher",
        "sterotypers" => "stereotyper",
        "tr" => "translator"
      }
      result = expectations.keys
        .map { |val| cleaner.call(val) }

      expect(result).to eq(expectations.values)
    end
  end
end
