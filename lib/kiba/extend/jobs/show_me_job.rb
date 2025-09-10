# frozen_string_literal: true

# rubocop:todo Layout/LineLength

require "kiba-common/dsl_extensions/show_me"

module Kiba
  module Extend
    module Jobs
      # Mixin to activate {Kiba::Common::DSLExtensions::ShowMe}
      #
      # @note Using settings/command line parameter to set `:show_me` to true will print the final
      #   result of the job to STDOUT. If you need to see the result at some specific point in your
      #   chain of transformations, you need to add the two lines in the `show` `job_segment` below
      #   to your transforms where you want the display to happen
      module ShowMeJob
        def decorate
          parse_job(control, context, [show])
        end

        def show
          Kiba.job_segment do
            extend Kiba::Common::DSLExtensions::ShowMe

            show_me!
          end
        end
      end
    end
  end
end
# rubocop:enable Layout/LineLength
