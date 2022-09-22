class Jobs < Runnable
  desc 'tagged TAG', 'List entries tagged with given tag and optionally run them'
  long_desc <<~LONG
  Lists entries tagged with given tag and optionally run them

  NOTE that the show, tell, and verbosity options are only relevant if you indicate the jobs should be run.
LONG
  
  def tagged(tag)
    getter = Kiba::Extend::Registry::RegistryEntrySelector.new
    result = getter.tagged_any(tag)
    return if result.empty?
    
    Kiba::Extend::Registry::RegistryList.new(result)

    return unless options[:run]

    run_jobs(result.map(&:key))
  end
end
