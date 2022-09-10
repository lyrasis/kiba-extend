# frozen_string_literal: true

module Kiba
  module Extend
    module Command
      module Runnable
        module_function
        
        def resolve_job(key)
          Kiba::Extend.registry.resolve(key)
        rescue Dry::Container::KeyError
          puts "No job with key: #{key}"
          :failure
        end

        def resolve_creator(job)
          creator = job.creator
          return creator if creator

          puts "No creator method for #{job.key}"
          :failure
        end

        def run_job(key)
          job = resolve_job(key)
          return if job == :failure

          creator = resolve_creator(job)
          return if creator == :failure

          creator.call
        end
      end
    end
  end
end
