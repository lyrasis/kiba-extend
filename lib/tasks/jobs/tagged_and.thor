class Jobs < Runnable
  desc 'tagged_and', 'List entries tagged with given tags, ANDed together, and optionally run them	'
  long_desc <<~LONG
  List entries tagged with given tags, ANDed together, and optionally run them

  NOTE that the show, tell, and verbosity options are only relevant if you indicate the jobs should be run.
LONG

  option :tags, required: true, type: :array, banner: 'TAG1 TAG2',
         desc: 'The tags for which to return entries'
  
  def tagged_and
    getter = Kiba::Extend::Registry::RegistryEntrySelector.new
    result = getter.tagged_all(options[:tags])
    return if result.empty?
    
    Kiba::Extend::Registry::RegistryList.new(result)

    return unless options[:run]

    result.map(&:key).each{ |key| run_job(key) }
  end
end
