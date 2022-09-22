# frozen_string_literal: true

module Kiba
  module Extend
    module Utils
      class PreJobNukeTask < PreJobTask
        class << self
          def call
            self.new.call
          end
        end

        def call
          return unless runnable?
          
          dirs.each do |dir|
            puts "Deleting files from #{dir}..."
            Dir.each_child(dir){ |f| FileUtils.rm("#{dir}/#{f}") }
          end
        end

        
        private

        def runnable?
          true if mode && dirs && !dirs.empty?
        end
      end
    end
  end
end
