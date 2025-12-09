<!--
# @markup markdown
# @title Common patterns, tips, and tricks
-->

# Common patterns, tips, and tricks


<!-- toc -->

- [Debugging with `pry`](#debugging-with-pry)
- [Multi-source jobs with CSV destination and sources don't have all the same fields](#multi-source-jobs-with-csv-destination-and-sources-dont-have-all-the-same-fields)
- [Using transform(s) within another transform](#using-transforms-within-another-transform)
- [Using transforms in job definitions](#using-transforms-in-job-definitions)
- [Calling a job with parameters](#calling-a-job-with-parameters)
- [Automating repetitive file registry](#automating-repetitive-file-registry)
- [Running jobs, and checking `srcrows` and `outrows` counts from client project code](#running-jobs-and-checking-srcrows-and-outrows-counts-from-client-project-code)

<!-- tocstop -->

## Debugging with `pry`

In most parts of a kiba-extend project, you can just put a `binding.pry` breakpoint anywhere in the code and it will work.

There are two exceptions to this: inside `Kiba.job_segment` blocks, and in any code where the breakpoint context interacts with the `dry-rb` gems that are used to build kiba-extend's registry and config functionality.

### In `Kiba.job_segment` blocks

Wrap your breakpoint in an inline transform:

~~~ ruby
transform do |row|
  binding.pry
  row
end
~~~

Note that you can set the breakpoint conditionally, if you want to see what's going on at this point in the job for rows with certain characteristics:

~~~ ruby
transform do |row|
  binding.pry if row[:id]&.start_with?("A")
  row
end
~~~

### Where `binding.pry` conflicts with `dry-rb` gem code or other code

It can be hard to predict when/where this is going to happen, but sometimes entering a `binding.pry` breakpoint in your code can result in the following kind of error:

~~~
RuntimeError:
        Cannot create Binding object for non-Ruby caller
~~~

Basically, any error message about [Binding objects](https://ruby-doc.org/3.4.1/Binding.html) means the breakpoint is getting misinterpreted based on other code around it.

The fix is easy: change your breakpoint to `Kernel.binding.pry`. This ensures `binding` is interpreted as the default method available on all Ruby objects via [Kernel](https://ruby-doc.org/3.4.1/Kernel.html).

## Multi-source jobs with CSV destination and sources don't have all the same fields

**Works for `Kiba::Extend::Destinations::CSV` destinations only**

If you have multiple sources for a job, writing to a CSV destination will fail if all rows in all sources do not have exactly the same fields.

Especially when joining data from many tables, manually ensuring columns stay in sync across all sources is very tedious, especially as you are developing a set of jobs.

**Recommended solution:** As of 4.0.0, you can fix this by adding `transform Clean::EnsureConsistentFields` to the end of tranform logic for multi-source jobs that output to CSV.

**Legacy solution (not recommended):** `Kiba::Extend::Utils::MultiSourceNormalizer` and `Kiba::Extend::Jobs::MultiSourcePrepJob` were introduced in v2.7.0 to address this issue, but will eventually be deprecated, as the `EnsureConsistentFields` transform is much easier to set up and use.

## Using transform(s) within another transform

### Aliasing/renaming a transform

This pattern is used with argument forwarding to deprecate/rename some transforms in kiba-extend, as shown below:

~~~ ruby
class Transformer
  def initialize(...)
    @xform = MyOtherTransformer.new(...)
  end

  def process(row)
    xform.process(row)
	row
  end

  private

  attr_reader :xform
end
~~~

### Adding some extra behavior to an existing transform in a new transform

It can also be used in order to compose additional behavior in another transform as shown below:

~~~ ruby
class NewTransformer
  def initialize(param1:, param2:)
    @param1 = param1
	@param2 = param2
	@xform = ExistingTransformer.new(opt1: :something)
  end

  def process(row)
    row[:field1] = param1
    xform.process(row) # calls the other transformer on the row
    row[:field2] = param2
	row
  end

  private

  attr_reader :param1, :param2, :xform
end
~~~

See the code for `Kiba::Extend::Transforms::Rename::Fields` for a simple example of embedding another transform to compose transformation logic.

See `Kiba::Extend::Transforms::Collapse::FieldsToRepeatableFieldGroup` for a complex example, involving many other transforms.

### Chaining multiple transforms in another transform

I often use this if I need to define a single, client-specific data cleanup transform class to be run from within kiba-tms, kiba-pastperfect_we, etc.

You can do:

~~~ ruby
class NewTransformer
  def initialize(...)
    @xforms = [
	  ExitingTransformer.new(...),
	  AnotherTransformer.new(...),
	  ThirdTransformer.new(...)
	]
  end

  # @private
  def process(row)
    xforms.each{ |xform| xform.process(row) }
	row
  end

  private

  attr_reader :xforms
end
~~~

### LIMITATIONS ON THE ABOVE

All of the above patterns should work with normal transforms---those that process one row at a time and always return that row.

Be careful including the following types of transforms in any of the above patterns:

* **Transforms that sometimes return the row and sometimes return nil.** Example: all the `Kiba::Extend::Transforms::FilterRows` transforms.
* **Transforms that can output more than one row from a given input row.** The `:process` method of such transforms will `yield` rows and return `nil`. Example: `Kiba::Extend::Transforms::Explode::RowsFromMultivalField`
* **Transforms that work on multiple rows (or the whole table) at a time** Such transforms will have a `:close` method that returns or yields rows. The `:process` method of such transforms will generally push rows to an accumulator Array or Hash defined as a class instance variable, and return `nil`. The `:close` method typically operates on the contents of the accumulator once all rows have been pushed into it. Example: `Kiba::Extend::Transforms::Deduplicate::Table`

These might work ok, but I haven't done enough testing to verify they are actually safe. Try it and see. If they work, make a PR to update this documentation!

## Using transforms in job definitions

The following code snippets are equivalent.

This one relies on the domain specific language (DSL) "magic" defined in kiba:

~~~ ruby
Kiba.job_segment do
  transform Merge::ConstantValue, target: :data_source, value: 'source system'
end
~~~

This one uses plain Ruby to set up two differently configured `Merge::ConstantValue` transform classes in the context of the job's transform logic. It then uses kiba's inline block transform functionality to call the appropriate transform's `:process` method on each row, depending on whether the :id field in the row starts with the given string:

~~~ ruby
Kiba.job_segment do
  exsrc = Merge::ConstantValue.new(target: :data_source, value: "spreadsheets")
  dbsrc = Merge::ConstantValue.new(target: :data_source, value: "database")
  transform do |row|
    idval = row[:id]
	if idval.start_with?("ACC")
	  dbsrc.process(row)
	else
	  exsrc.process(row)
	end
	# You don't need to return "row" here because calling `:process` on a
	#   `Merge::ConstantValue` transform returns a row
  end
end
~~~

This is a silly, contrived, example that offers no benefits over just doing the whole thing in the block transform:

~~~ ruby
Kiba.job_segment do
  transform do |row|
    idval = row[:id]
	target = :data_source
	row[target] = if idval.start_with?("ACC")
	  "database"
	else
	  "spreadsheets"
	end

	row # A block transform must return `nil` or a row.
  end
end
~~~

However, you might run into ways where you need to use transforms more flexibly, and this basic idea might help.

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

~~~
job = Kiba::Extend::Command::Run.job(:prep__objects)
puts "Some records omitted" if job.outrows < job.srcrows
~~~

This assumes `:prep__objects` is registered as a job.

This is being used in the publicly available `kiba-tms` project, in the auto-config generation and to-do check processes. [Examples](https://github.com/lyrasis/kiba-tms/search?q=Kiba%3A%3AExtend%3A%3ACommand%3A%3ARun.job)

Since 4.0.0, you can use [the `Kiba::Extend::Job.output?` method](https://lyrasis.github.io/kiba-extend/Kiba/Extend/Job.html#output%3F-class_method) to check that a job writes a file with actual data rows in it. This is helpful if you start writing dynamic/reusable code for projects that might not all have the exact same data. You can conditionally run some parts of a pipeline, only if the data is present.
