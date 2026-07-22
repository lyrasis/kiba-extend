# frozen_string_literal: true

class Debug < Thor
  desc "string_tags", "list tags that are Strings, not Symbols"
  def string_tags
    puts Kiba::Extend::Command::Reg.tags
      .reject { |tag| tag.is_a?(Symbol) }
  end
end
