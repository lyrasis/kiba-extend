# Kiba::Extend

Kiba is a [Data processing & ETL framework for Ruby](https://github.com/thbar/kiba).

kiba-extend is a suite of Kiba extensions useful in transforming and reshaping data. It includes the following:

- An extensive library of abstract, reusable transformations
- Some custom source and destination types
- File/job registry support for use in migration projects. This handles repetitive aspects of configuring source, lookup, and destination files, as well as ensures dependency jobs are called to create files created for a given job. Files/jobs may be tagged and run from a project application via Rake tasks
- Job templating and decoration. No need to repeat the same source/destination setup, requirements running, pre-processing, post-processing, and initial/final transforms over and over again in your ETL code.

Some current possibilities with job templating/decoration:

- You can turn on "show me!" when you run a job via Rake task, without doing anything in your code.
- You can similarly turn on "tell me" from the command line, which will have your computer say something when a job is complete---useful for long running jobs.
- There is a TestingJob that can be used to set up automated tests for sequences of transforms (i.e. job definition xforms/segments)

**The transformations and source/destination types may be used completely independently of the registry/job templating.** The registry and job templating functionality are highly dependent on one another.

On the to-do list:

- Wiki documentation for how to use the registry and job templating. In the meantime the best place to get an understanding of this is [kiba-extend-project](https://github.com/lyrasis/kiba-extend-project).

## Documentation
### https://lyrasis.github.io/kiba-extend/

Browseable reference for available transformations.

**Look under [Files](https://lyrasis.github.io/kiba-extend/file_list.html) for in-depth information on broader topics than can be covered in the code documentation.**

I'm working to develop this more fully. If there is no documentation for a given transformation here, please refer to the relevant `spec` file for that transformation to see exactly what it does.

### Specs
To get a full overview of available transformations and what they do, run `rake spec` from the repo base directory. This will give you the names of all the transformations in `kiba-extend` and brief descriptions of what they do.

For more clarity about exactly what each transformation does, if it is not described in the documentation yet, check the actual test files in `/spec/kiba/extend/transforms`, which include sample input rows, transformation calls, and the resulting output

## Example project applications

[kiba-extend-project](https://github.com/lyrasis/kiba-extend-project) is a Github template repository for starting a new ETL project using `kiba-extend`. It is heavily commented in an attempt to explain how things work.

[kiba-tms](https://github.com/lyrasis/kiba-tms/) is a publicly available project not for a specific client. It uses `kiba-extend` to handle most of the data transformations required for a TMS->CollectionSpace migration. It makes heavy use of `dry-configurable` settings and probably ill-advised metaprogramming to account for the fact that every client uses TMS differently and thus basically everything needs to be configurable. [Private, client-specific repos for individual TMS->CollectionSpace migration clients](https://cs.github.com/?scope=org%3Alyrasis&scopeName=lyrasis&q=gem+%27kiba-tms%27) that require `kiba-tms` are set up to define client-specific migration configs, transforms, and jobs.

[mimsy-to-cspace](https://github.com/lyrasis/mimsy-to-cspace) is a publicly available example of `kiba-extend` usage. It was completed before the registry/job templating functions were added, so it only shows how transformations get used. (And it is a good example of how repetitive the code gets without templating)

LYRASIS staff with permissions to private repos can find a number of other project examples using `kiba-extend` [in our organizationrepo list](https://cs.github.com/?scope=org%3Alyrasis&scopeName=lyrasis&q=gem+%27kiba-extend%27)
