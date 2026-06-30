# frozen_string_literal: true

module Kiba
  module Extend
    module Utils
      # RSpec helpers to mix in your project

      # To set up, include this module in your project's RSpec config. You
      #   will add a line like the one below in your project's
      #   `./spec/spec_helper.rb`:
      #
      # ~~~~ruby
      # RSpec.configure do |config|
      #   config.include Kiba::Extend::Utils::TestHelpers
      # end
      # ~~~~
      #
      # There are probably ways to use these with other testing frameworks,
      #   but we're not testing and documenting Minitest or anything else,
      #   since kiba-extend and its sample project use RSpec
      module TestHelpers
        module_function

        # Run the job if its output file doesn't exist; parse the output
        #   CSV
        #
        # Usage example testing that all rows of the given job's output
        #   have `:matchtype` field values of "none" :
        #
        # ~~~~ruby
        # require "spec_helper"
        #
        # RSpec.describe Project::Jobs::NonRefnameAuth do
        #   describe ":non_refname_auth__final" do
        #     let(:data) { csv_job_output(:non_refname_auth__final) }
        #
        #     it "only includes none matchtypes" do
        #       result = data[:matchtype].all? { |e| e == 'none' }
        #       expect(result).to be true
        #     end
        #   end
        # end
        # ~~~~
        # @param jobkey [Symbol]
        # @return [CSV::Table]
        def csv_job_output(jobkey)
          path = Kiba::Extend.registry
            .resolve(jobkey)
            .path
          Kiba::Extend::Command::Run.job(jobkey) unless File.exist?(path)
          return unless File.exist?(path)

          CSV.parse(File.read(path), **Kiba::Extend.csvopts)
        end
      end
    end
  end
end
