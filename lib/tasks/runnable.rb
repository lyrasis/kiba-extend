require 'thor'

class Runnable < Thor
  class_option :show, required: false, type: :boolean, default: false, aliases: :s,
    desc: 'Whether to print job results to STDOUT. Default: false'
  class_option :tell, required: false, type: :boolean, default: false, aliases: :t,
    desc: 'Whether to SAY job is complete. Useful for long running jobs. Default: false'
  class_option :verbosity, required: false, type: :string, default: 'normal', aliases: :v,
    desc: 'How much info to print to screen',
    enum: ['minimal', 'normal', 'verbose']

  private

  def preprocess_options
    Kiba::Extend.config.job.show_me = options[:show]
    Kiba::Extend.config.job.tell_me = options[:tell]
    Kiba::Extend.config.job.verbosity = options[:verbosity].to_sym
  end

  def run_jobs(keys)
    preprocess_options
    Kiba::Extend::Utils::PreJobTask.call
    keys.each{ |key| Kiba::Extend::Command::Run.job(key) }
  end
end
