class Jobs < Thor
  desc 'tagged TAG', 'List entries tagged with given tag'
  def tagged(tag)
    getter = Kiba::Extend::Registry::RegistryEntrySelector.new
    result = getter.tagged_any(tag)
    return if result.empty?
    
    Kiba::Extend::Registry::RegistryList.new(result)

    return unless options[:run]
    result.each{ |res| puts "RUN #{res}" }
  end
end
