require 'thor'

class Run < Thor
  class_option :show, required: false, type: :boolean, default: false, aliases: :s,
               desc: 'Whether to print job results to STDOUT'
  class_option :tell, required: false, type: :boolean, default: false, aliases: :t,
               desc: 'Whether to SAY job is complete. Useful for long running jobs'
  class_option :verbosity, required: false, type: :string, default: 'normal', aliases: :v,
               desc: 'How much info to print to screen',
               enum: ['minimal', 'normal', 'verbose']

  private

  def preprocess_options
    Kiba::Extend.config.job.show_me = options[:show]
    Kiba::Extend.config.job.tell_me = options[:tell]
    Kiba::Extend.config.job.verbosity = options[:verbosity].to_sym
  end

  def resolve_job(key)
    Kiba::Extend.registry.resolve(options[:key])
  rescue Dry::Container::Error
    puts "No job with key: #{key}"
    :failure
  end

  def resolve_creator(job)
    creator = job.creator
    return creator if creator

    puts "No creator method for #{job.key}"
    :failure
  end
end
