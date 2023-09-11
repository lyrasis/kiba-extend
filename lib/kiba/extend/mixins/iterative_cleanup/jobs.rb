# frozen_string_literal: true

module Kiba
  module Extend
    module Mixins
      module IterativeCleanup
        # Namespace for jobs set up via extending the {Mixins::IterativeCleanup}
        #   module
        #
        # Each job is passed `mod` when it is called. This is the
        #   cleanup config module that extends
        #   {Mixins::IterativeCleanup}. The job refers to
        #   configuration settings from the config module to
        #   dynamically define the job at runtime.
        #
        # Each job defined in this namespace has a set of standard
        #   transforms, which can be viewed in the source of its
        #   `xforms` method
        #
        # The extending config module may define custom transforms to
        #   be run pre and/or post the standard transforms for each
        #   job. The pattern for doing this is:
        #
        # - Take the name of the relevant job module, e.g.
        # - {Jobs::BaseJobCleaned}
        # - Convert it to lowercase snake case, e.g. base_job_cleaned
        # - Indicate pre or post standard transforms: e.g.
        #   base_job_cleaned_pre_xforms or
        #   base_job_cleaned_post_xforms. **This is the name of the
        #   method you define in the extending configuration module**.
        # - The method definition should be just as the `xforms`
        #   methods in all jobs. It should be a set of transforms
        #   defined within a `Kiba.job_segment` block. If the custom
        #   xforms method needs to call methods/settings defined in
        #   the config module, use `binding` as shown below:
        #
        # ```ruby
        #   def base_job_cleaned_post_xforms
        #     bind = binding
        #
        #     Kiba.job_segment do
        #       mod = bind.receiver
        #
        #       transform Delete::Fields,
        #         fields: mod.post_xform_delete_fields
        #     end
        #   end
        # ```
        module Jobs
        end
      end
    end
  end
end
