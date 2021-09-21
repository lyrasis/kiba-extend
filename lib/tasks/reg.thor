require 'thor'

# registry tasks
class Reg < Thor  
  desc 'list', 'List all entries in file registry with file key, path, description, and creator'
  def list
    puts Kiba::Extend::Registry::RegistryList.new
  end


  desc 'tagged_and', 'List entries tagged with given tags, ANDed together'
  option :tags, required: true, type: :array, aliases: :t, banner: 'reports warnings',
         desc: 'The tags for which to return entries'
  def tagged_and
    getter = Kiba::Extend::Registry::RegistryEntrySelector.new
    result = getter.tagged_all(options[:tags])
    return if result.empty?
    
    Kiba::Extend::Registry::RegistryList.new(result)
  end

  desc 'tagged_or', 'List entries tagged with given tags, ORed together'
  option :tags, required: true, type: :array, aliases: :t, banner: 'reports warnings',
         desc: 'The tags for which to return entries'
  def tagged_or
    getter = Kiba::Extend::Registry::RegistryEntrySelector.new
    result = getter.tagged_any(options[:tags])
    return if result.empty?
    
    Kiba::Extend::Registry::RegistryList.new(result)
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
