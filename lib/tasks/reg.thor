# frozen_string_literal: true

require "thor"

# registry tasks
class Reg < Thor
  desc "list", "List all entries in file registry with file key, path, "\
    "description, and creator"
  def list
    Kiba::Extend::Command::Reg.list
  end

  desc "tags", "List tags used in the registry"
  def tags
    puts Kiba::Extend::Command::Reg.tags.sort
  rescue ArgumentError
    puts "It looks like you have at least one non-Symbol tag. "\
      "Try `thor debug string_tags` to list these so you can fix them."
  end

  desc "validate", "List entries in file registry with errors and warnings"
  def validate
    Kiba::Extend::Command::Reg.validate
  end
end
