# Command line interface (CLI) for running jobs/tasks

`kiba-extend` uses [Thor](http://whatisthor.com/) to provide a command line interface for working with your ETL project. 

I chose Thor over Rake because it is awkward to pass options/parameters in Rake, and because automated testing of Rake tasks is convoluted. ([ref](https://technology.doximity.com/articles/move-over-rake-thor-is-the-new-king))

## Help on the CLI

The following command will list all available tasks. 

`thor -T`

This lets you search for only tasks beginning with "reg":

`thor list reg`

Some of the task descriptions may be truncated in the display, though. This also doesn't tell you what parameters/options you can pass in. 

To get more details on a given task: 

`thor --help TASKNAME`

For example: `thor --help reg:list` or `thor --help jobs:tagged`

### Conventions in the help

#### Plain parameters

When you see: 

```
Usage:
  thor jobs:tagged TAG
```

The all caps word is a placeholder for a parameter that gets passed in without an option flag. For example, the following returns a list of jobs tagged with "report":

`thor jobs:tagged report`

#### Boolean options

Boolean options are presented a bit oddly in the help. For example: 

```
Options:
  r, [--run], [--no-run]      # Whether to run the matching jobs
```

Any of the following will work, according to your preference:

To find the jobs, list, and run them:

```
thor jobs:tagged report -r true
thor jobs:tagged cspace --run
thor jobs:tagged -r true cspace
thor jobs:tagged --run true cspace
thor jobs:tagged --run cspace
```

The find and list the jobs without running them:

```
thor jobs:tagged report -r false
thor jobs:tagged cspace --no-run
thor jobs:tagged -r false cspace
thor jobs:tagged --run false cspace
thor jobs:tagged --no-run cspace
```

However the following **does** run the jobs, so use one of the more straightforward options above:

```
thor jobs:tagged cspace --no-run true
```

#### Other options

```
Usage:
  v, [--verbosity=VERBOSITY]  # Only relevant if run=true. How much info to print to screen
                              # Default: normal
                              # Possible values: minimal, normal, verbose
```

In this case, replace the all-caps word with one of the possible values (if listed), or your uncontrolled string.

To use the full option name: 

`thor jobs:tagged cspace --run --verbosity=verbose`

To use the alias:

`thor jobs:tagged cspace --run -v verbose`

## Architecture/design

Thor tasks are defined in `kiba-extend/lib/tasks`.

There is a Thorfile in the `kiba-extend` base directory that autoloads those tasks and runs the CLI when you type thor commands. (How this works is some kinda ruby/thor library magic I haven't dug into fully).

Your ETL project base directory (if following the repo template/FWM example), will also have a Thorfile in its base directory, which will call in all of `kiba-extend`'s tasks, as well as any you create in your own repo's `/lib/tasks` directory.

