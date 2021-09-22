require 'thor'

# registry tasks
class Reg < Thor  
  desc 'list', 'List all entries in file registry with file key, path, description, and creator'
  def list
    puts Kiba::Extend::Registry::RegistryList.new
  end

  desc 'tags', 'List tags used in the registry'
  def tags
    tags = []
    Kiba::Extend.registry.entries.each do |entry|
      entrytags = entry.tags
      next if entrytags.blank?

      tags << entrytags
    end
    clean = tags.flatten.sort.uniq
    puts clean
  end

  desc 'validate', 'List entries in file registry with errors and warnings'
  def validate
    Kiba::Extend::Registry::RegistryValidator.new.report
  end
end
