# frozen_string_literal: true

require "marc"

module Kiba
  module Extend
    module Utils
      # Callable service to clean punctuation off end of name string
      class MarcRoleTermCleaner
        # @param value [String]
        # @return [String]
        def call(value)
          value.sub(/,$/, "")
            .sub(/([^ .].)\.$/, '\1')
            .sub(/^\((.*)\)$/, '\1')
            .sub(/ ?\((work|expression|manifestation|item)\)/, "")
            .sub(/^comp$/i, "compiler")
            .sub(/^comp\. and ed$/i, "compiler|editor")
            .sub(/^ed$/, "editor")
            .sub(/^engr$/, "engraver")
            .sub(/^illus$/, "illustrator")
            .sub(/^pbl$/, "publisher")
            .sub(/^tr$/, "translator")
            .sub(/^(engraver|architect|illustrator|publisher|stereotyper)s$/, '\1')
        end
      end
    end
  end
end
