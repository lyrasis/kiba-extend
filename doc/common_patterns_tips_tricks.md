# Common patterns, tips, and tricks

## Troubleshooting `MissingDependencyError` when all dependencies are set up as expected

Usually the cause of a `MissingDependencyError` is that a table required in some later job unexpectedly ends up with no rows, and thus is not written out. 

So the dependent job is set up properly, but the expected output doesn't exist. 

I can't think of a way to handle this better, given that, when there are no rows to write out to a Destination, we don't even know what the expected headers would have been in order to write a headers-only CSV.

## Joining the rows of multiple sources that may have different fields

**Works for `Kiba::Extend::Destinations::CSV` destinations only**

If you have multiple sources for a job, writing to a CSV destination will fail if all rows in all sources do not have exactly the same fields.

Especially when joining data from many tables, manually ensuring columns stay in sync across all sources is very tedious, especially as you are developing a set of jobs. 

As of v2.7.0, {Kiba::Extend::Utils::MultiSourceNormalizer} and {Kiba::Extend::Jobs::MultiSourcePrepJob} are added to support handling this automagically. 

See {Kiba::Extend::Utils::MultiSourceNormalizer} for full usage docs.

See [name compilation jobs in Kiba::TMS](https://github.com/lyrasis/kiba-tms/blob/main/lib/kiba/tms/jobs/in_between/name_compilation.rb) for working example of use.

## Calling a transform from within another transform

This pattern is used with argument forwarding to deprecate/rename some transforms in kiba-extend, as shown below: 

```
class Transformer
  def initialize(...)
    @xform = MyOtherTransformer.new(...)
  end

  # @private
  def process(row)
    xform.process(row)
  end
  
  private
  
  attr_reader :xform
end
```

It can also be useful in other transforms as shown below:


```
class Transformer
  def initialize(param1:, param2:)
    @param1 = param1
	@param2 = param2
	@otherxform = OtherTransformer.new(opt1: :something)
  end

  # @private
  def process(row)
    # do stuff to row
    otherxform.process(row)
    # do more stuff to row
	row
  end
  
  private
  
  attr_reader :param1, :param2, :otherxform
end
```

See the code for {Kiba::Extend::Transforms::Rename::Fields} for an example of embedding another transform to compose transformation logic.

## Calling a job with parameters

No need to write repetitive jobs with the exact same logic to handle variable values that differ according to a pattern. See [File registry documentation on Hash creator](https://lyrasis.github.io/kiba-extend/file.file_registry_entry.html#hash-creator-example-since-2-7-2) for a full example of how to do this.

## Automating repetitive file registry

The basic idea of this is: 

* write code that generates `Project.registry` `register` commands with registry keys and hashes, according to the necessary pattern.
* call this code from within `Project::RegistryData.register` before `register_files` is called. 

One pattern for doing this is publicly viewable [in the `kiba-tms` project](https://github.com/lyrasis/csws-update/blob/main/lib/csws/registry_data.rb#L7-L15). `register_supplied_files` automates registry of the original TMS CSV files included in the project. `register_prep_files` automates the creation of entries for all original files into a `prep` namespace. If a custom prep method or module has been creating matching the name pattern, it will be used as the creator. Otherwise, the creator will be [`Kiba::Tms::Jobs::AbstractPrep`](https://github.com/lyrasis/kiba-tms/blob/main/lib/kiba/tms/jobs/abstract_prep.rb), which removes TMS-specific fields and deletes any empty fields. 

Another example (in LYRASIS private repo) is [here](https://github.com/lyrasis/csws-update/blob/main/lib/csws/registry_data.rb#L7-L15).

## Running jobs, and checking `srcrows` and `outrows` counts from client project code

Since 3.1.0, you can do this from any project using `kiba-extend`: 

```
job = Kiba::Extend::Command::Run.job(:prep__objects)
puts "Some records omitted" if job.outrows < job.srcrows
```

This assumes `:prep__objects` is registered as a job.

This is being used in the publicly available `kiba-tms` project, in the auto-config generation and to-do check processes. [Examples](https://github.com/lyrasis/kiba-tms/search?q=Kiba%3A%3AExtend%3A%3ACommand%3A%3ARun.job)

