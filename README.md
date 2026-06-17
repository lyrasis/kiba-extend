# Kiba::Extend

Kiba is a [Data processing & ETL framework for Ruby](https://github.com/thbar/kiba).

kiba-extend is a suite of Kiba extensions useful in transforming and reshaping data.
It has been developed in the context of performing complex custom data migration projects.
These projects tend to have the following features, which have informed the funtionality included in kiba-extend:

- Even when the source system is the same for 5 clients, data entry practice and use of modules/fields will vary, often wildly.
- They can take a long time because they frequently involve (a) a significant level of client instruction on the function of the target system, so they can understand the impact of different data mapping decisions; (b) clients who must make migration mapping decisions by committee; and/or (c) a significant amount of work to render the data functional for the target system.
- The source system often does not allow the client to get a view of the data that would be required to make migration decisions for that data. It also usually does not provide any way for the client to do any data cleanup or categorization needed to prepare for a migration, other than record-by-record editing.
- Active use of the source system for critical work, which cannot be put on hold for the entire time it takes us to work with the client to develop their migration. This means we are often developing the migration
- Most of our clients are not data experts or incredibly technically savvy. They tend to be most comfortable reviewing data in a tabular data format (CSV or Excel file).

It includes the following:

- An extensive library of abstract, reusable data transformations that can be used to create custom transformation jobs
- Some custom [source](https://lyrasis.github.io/kiba-extend/Kiba/Extend/Sources.html) and [destination](https://lyrasis.github.io/kiba-extend/Kiba/Extend/Destinations.html) types
- File/job registry support for use in migration projects. This handles repetitive aspects of configuring source, lookup, and destination files, as well as ensures dependency jobs are called to create files created for a given job. Files/jobs may be tagged and run from a project application via Thor tasks
- Job templating and decoration. No need to repeat the same source/destination setup, requirements running, pre-processing, post-processing, and initial/final transforms over and over again in your ETL code.
- Support for [iterative cleanup processes](https://lyrasis.github.io/kiba-extend/file.iterative_cleanup.html)

Some current possibilities with job templating/decoration:

- You can turn on "show me!" when you run a job via Thor task, without doing anything in your code. This causes the output to be emitted to STDOUT.
- You can similarly turn on "tell me" from the command line, which will have your computer say something when a job is complete---useful for long running jobs. **This is currently really annoying for jobs with dependencies, as all dependency job completions will also be announced.**

**The transformations and source/destination types may be used completely independently of the registry/job templating.** The registry and job templating functionality are highly dependent on one another.


One powerful way of using kiba-extend is to create an "abstract" ETL project.
An abstract project handles the general logic of transforming data from a specific source system into the format required by a given target system.
For example, if you frequently need to migrate data from OldSystem to NewSystem, you may create an abstract OldSystem kiba-extend project that can handle the general structure of data out of OldSystem and its transformation:what the source data files are, hardcoded enum values that need to be replaced in the data, what preprocessing needs to be done, how to merge data from lookup tables into the records using the lookups, and remapping the data into the "shape" you need it to be in for NewSystem.

All the specifics that may change per specific instance of such a project are defined as configuration settings in the abstract project.
For instance one OldSystem user may only want to migrate records with `active=true` values to NewSystem, while another may wish to also migrate all records regardless of `active` status.

You would create a new kiba-extend project for each of these clients.
These client projects would have your abstract project as a dependency.
This is where you would set the per-project configuration settings you defined in the abstract project.
You can also define client-specific jobs and transforms here as needed.

On the to-do list:

- Wiki documentation for how to use the registry and job templating. In the meantime the best place to get an understanding of this is [kiba-extend-project](https://github.com/lyrasis/kiba-extend-project).

## Non-Ruby/non-bundleable dependencies {#dep}

### Rendering mermaid job dependency graphs {#mermaidrenderdep}

If you wish to use the `thor job graph` command to render mermaid dependency graphs, you need to install the https://github.com/coolamit/mermaid-cli[the Go mmd-cli]. This is a replacement for the official mermaid.js/mermaid-cli, which is embedded deeply in the node/npm ecosystem, and which has some really annoying and problematic dependencies and Mac bugs.

The preferred way to do this in the Lyrasis Data Migrations team environment is via https://mise.jdx.dev[mise] and then go's install command:

Install go if you do not already have it:

    mise use -g go@1.25.11 # or later version

Install chromium. This is becoming more problematic, as the brew version doesn't work, and conflicts with ARM architecture exist. As of June 2026, https://github.com/ungoogled-software/ungoogled-chromium-macos[Ungoogled Chromium for the MacOS] works:

    brew install --cask ungoogled-chromium

Install mermaid-cli:

    go install github.com/coolamit/mermaid-cli/cmd/mmd-cli@latest

Alternate installation paths are documented at https://github.com/mermaid-js/mermaid-cli[the mermaid-cli GitHub repository].

If you ever want to uninstall mmd-cli, do `which mmd-cli` and then delete the directory at that path.

## Documentation

[API documentation](https://lyrasis.github.io/kiba-extend/)

**Look under [Files](https://lyrasis.github.io/kiba-extend/file_list.html) for in-depth information on broader topics than can be covered in the code documentation.**

I'm working to develop this more fully. If there is no documentation for a given transformation here, please refer to the relevant `spec` file for that transformation to see exactly what it does.

### Specs
To get a full overview of available transformations and what they do, run `bundle exec rspec` from the repo base directory. This will give you the names of all the transformations in `kiba-extend` and brief descriptions of what they do.

For more clarity about exactly what each transformation does, if it is not described in the documentation yet, check the actual test files in `/spec/kiba/extend/transforms`, which include sample input rows, transformation calls, and the resulting output

## Example project applications

[kiba-extend-project](https://github.com/lyrasis/kiba-extend-project) is a Github template repository for starting a new ETL project using `kiba-extend`. It is heavily commented in an attempt to explain how things work.

## Contributing

Please see [Contributing to `kiba-extend`](https://lyrasis.github.io/kiba-extend/file.contributing.html) for contributor guidelines.
