<!--
# @markup markdown
# @title Common patterns, tips, and tricks
-->

- TOC
{:toc}

## Debugging with `pry` {#pry}

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

## Multi-source jobs with CSV destination and sources don't have all the same fields {#csv-inconsistent-fields}

**Works for `Kiba::Extend::Destinations::CSV` destinations only**

If you have multiple sources for a job, writing to a CSV destination will fail if all rows in all sources do not have exactly the same fields.

Especially when joining data from many tables, manually ensuring columns stay in sync across all sources is very tedious, especially as you are developing a set of jobs.

As of 4.0.0, you can fix this by adding `transform Clean::EnsureConsistentFields` to the end of tranform logic for multi-source jobs that output to CSV.

## Using transform(s) within another transform {#xform-in-xform}

### Aliasing/renaming a transform {#alias-rename-xform}

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

### Chaining multiple transforms in another transform {#chaining-xforms}

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

#### LIMITATIONS ON THE ABOVE {#chaining-limitations}

All of the above patterns should work with normal transforms---those that process one row at a time and always return that row.

Be careful including the following types of transforms in any of the above patterns:

* **Transforms that sometimes return the row and sometimes return nil.** Example: all the `Kiba::Extend::Transforms::FilterRows` transforms.
* **Transforms that can output more than one row from a given input row.** The `:process` method of such transforms will `yield` rows and return `nil`. Example: `Kiba::Extend::Transforms::Explode::RowsFromMultivalField`
* **Transforms that work on multiple rows (or the whole table) at a time** Such transforms will have a `:close` method that returns or yields rows. The `:process` method of such transforms will generally push rows to an accumulator Array or Hash defined as a class instance variable, and return `nil`. The `:close` method typically operates on the contents of the accumulator once all rows have been pushed into it. Example: `Kiba::Extend::Transforms::Deduplicate::Table`

These might work ok, but I haven't done enough testing to verify they are actually safe. Try it and see. If they work, make a PR to update this documentation!

## Using transforms in job definitions {#xforms-in-jobs}

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

## Calling a job with parameters {#jobs-with-params}

No need to write repetitive jobs with the exact same logic to handle variable values that differ according to a pattern. See [File registry documentation on Hash creator](https://lyrasis.github.io/kiba-extend/file.file_registry_entry.html#hash-creator-example-since-2-7-2) for a full example of how to do this.

## Automating repetitive file registry {#auto-register}

The basic idea of this is:

* write code that generates `Project.registry` `register` commands with registry keys and hashes, according to the necessary pattern.
* call this code from within `Project::RegistryData.register` before `register_files` is called.

One pattern for doing this is publicly viewable [in the `kiba-tms` project](https://github.com/lyrasis/csws-update/blob/main/lib/csws/registry_data.rb#L7-L15). `register_supplied_files` automates registry of the original TMS CSV files included in the project. `register_prep_files` automates the creation of entries for all original files into a `prep` namespace. If a custom prep method or module has been creating matching the name pattern, it will be used as the creator. Otherwise, the creator will be [`Kiba::Tms::Jobs::AbstractPrep`](https://github.com/lyrasis/kiba-tms/blob/main/lib/kiba/tms/jobs/abstract_prep.rb), which removes TMS-specific fields and deletes any empty fields.

Another example (in LYRASIS private repo) is [here](https://github.com/lyrasis/csws-update/blob/main/lib/csws/registry_data.rb#L7-L15).

## Checking job output dynamically from client project code {#output-check}

### `srcrows` and `outrows` {#srcrows-outrows}

Since 3.1.0, you can do this from any project using `kiba-extend`:

~~~ ruby
job = Kiba::Extend::Command::Run.job(:prep__objects)
puts "Some records omitted" if job.outrows < job.srcrows
~~~

This assumes `:prep__objects` is registered as a job.

This is being used in the publicly available `kiba-tms` project, in the auto-config generation and to-do check processes. [Examples](https://github.com/lyrasis/kiba-tms/search?q=Kiba%3A%3AExtend%3A%3ACommand%3A%3ARun.job)

### `Kiba::Extend::Job.output?` {#output-method}

Since 4.0.0, you can use [the `Kiba::Extend::Job.output?` method](https://lyrasis.github.io/kiba-extend/Kiba/Extend/Job.html#output%3F-class_method) to check that a job writes a file with actual data rows in it. This is helpful if you start writing dynamic/reusable code for projects that might not all have the exact same data. You can conditionally run some parts of a pipeline, only if the data is present.

Basic usage of this method assumes the job you are checking for _is_ registered, but may or may not produce output. It prints a warning to STDOUT if the job is not registered.

In even wilder dynamic projects, you may not care if the job is registered or not. In this case, the following usage will be your friend:

~~~ ruby
Kiba::Extend::Job.output?(:prep__objects, mode: :agnostic)
~~~

## `Kiba::Extend::Job.registered?` {#job-registered}

[This method](https://lyrasis.github.io/kiba-extend/Kiba/Extend/Job.html#registered%3F-class_method) just returns a Boolean indicating whether the given job is registered or not.

## Manipulating the registry on the fly {#manipulate-registry}

Ok, so this isn't really a common pattern.

I have come up with this while working on a project with nearly 200 input data tables, where the project needs to be built up in very distinct phases, and there are 9 different categories of tables that need to be dealt with separately.

I want to be able to get `main` and `added_fields` categories of tables through the `preprocess`, `fix`, `fcar` phases to the `skeleton` (e.g. initial stub record ingest) phase before I deal with getting the other 7 categories of tables handled by the `fix` phase.

To do this, I am auto-registering:

* `preprocess` phase jobs based on the files in the `orig` directory
* `fix` phase jobs based on the files in the `preprocess` directory
* ...and so on as the phases continue

But this breaks the dependency-handling assumptions of kiba-extend. If I want to dynamically call a `fix` phase job from the `fcar` phase, but haven't run the corresponding `preprocess` job (or the results are cleared out by pre-job task deletion), the `fix` job I need will not be registered.

I can't just register all the eventual jobs based on the `orig` files, because referenced paths are validated when your registry data entries are initially registered at startup.

Here's the code I've got working to handle this situation:

### `reset_registry` method {#resetregistry}

In the /lib/my_project.rb file, inside the MyProject module definition:

~~~ ruby
def reset_registry
  Kiba::Extend.config.registry =
    Kiba::Extend::Registry::FileRegistry.new
  MyProject.config.registry = Kiba::Extend.registry
  MyProject::RegistryData.register
end
~~~

### Use where needed {#dynamicuse}

In the transform (or other) class that needs to dynamically make lookups after registry is regenerated:

~~~ ruby
fix_jobkey = :"fix_main__#{table}"
unless Kiba::Extend::Job.registered?(fix_jobkey)
  Kiba::Extend::Command::Run.job(:"preprocess_main__#{table}")
  MyProject.reset_registry
end
~~~


By design, the job registry is frozen and immutable, so this feels sort of evil. But it gets the job done for this strange project.
