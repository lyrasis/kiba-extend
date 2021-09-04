require 'thor'

class Jobs < Thor
  class_option :run, required: false, type: :boolean, default: false, aliases: :r,
               desc: 'Whether to run the matching jobs'
  class_option :show, required: false, type: :boolean, default: false, aliases: :s,
               desc: 'Only relevant if run=true. Whether to print job results to STDOUT'
  class_option :tell, required: false, type: :boolean, default: false, aliases: :t,
               desc: 'Only relevant if run=true. Whether to SAY job is complete. Useful for long running jobs'
  class_option :verbosity, required: false, type: :string, default: 'normal', aliases: :v,
               desc: 'Only relevant if run=true. How much info to print to screen',
               enum: ['minimal', 'normal', 'verbose']
end
