<!--
# @markup markdown
# @title Common patterns, tips, and tricks
-->

# Common patterns, tips, and tricks

## Joining the rows of multiple sources that may have different fields

**Works for `Kiba::Extend::Destinations::CSV` destinations only**

If you have multiple sources for a job, writing to a CSV destination will fail if all rows in all sources do not have exactly the same fields.

Especially when joining data from many tables, manually ensuring columns stay in sync across all sources is very tedious, especially as you are developing a set of jobs.

As of v2.7.0, {Kiba::Extend::Utils::MultiSourceNormalizer} and {Kiba::Extend::Jobs::MultiSourcePrepJob} are added to support handling this automagically.

See {Kiba::Extend::Utils::MultiSourceNormalizer} for full usage docs.

See [name compilation jobs in Kiba::TMS](https://github.com/lyrasis/kiba-tms/blob/main/lib/kiba/tms/jobs/in_between/name_compilation.rb) for working example of use.

## Using transform(s) within another transform

### Aliasing/renaming a transform

This pattern is used with argument forwarding to deprecate/rename some transforms in kiba-extend, as shown below:

~~~
class Transformer
  def initialize(...)
    @xform = MyOtherTransformer.new(...)
  end

  # @private
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

~~~
class NewTransformer
  def initialize(param1:, param2:)
    @param1 = param1
	@param2 = param2
	@xform = ExistingTransformer.new(opt1: :something)
  end

  # @private
  def process(row)
    # do stuff to row
    xform.process(row)
    # do more stuff to row
	row
  end

  private

  attr_reader :param1, :param2, :xform
end
~~~

See the code for {Kiba::Extend::Transforms::Rename::Fields} for a simple example of embedding another transform to compose transformation logic.

See {Kiba::Extend::Transforms::Collapse::FieldsToRepeatableFieldGroup} for a complex example, involving many other transforms.

### Chaining multiple transforms in another transform

You can do:

~~~
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

* **Transforms that sometimes return the row and sometimes return nil.** Example: all the {Kiba::Extend::Transforms::FilterRows} transforms.
* **Transforms that can output more than one row from a given input row.** The `:process` method of such transforms will `yield` rows and return `nil`. Example: {Kiba::Extend::Transforms::Explode::RowsFromMultivalField}
* **Transforms that work on multiple rows (or the whole table) at a time** Such transforms will have a `:close` method that returns or yields rows. The `:process` method of such transforms will generally push rows to an accumulator Array or Hash defined as a class instance variable, and return `nil`. The `:close` method typically operates on the contents of the accumulator once all rows have been pushed into it. Example: {Kiba::Extend::Transforms::Deduplicate::Table}


## Using transforms in job definitions

The following code snippets are equivalent.

This one relies on the domain specific language (DSL) "magic" defined in kiba:

~~~
Kiba.job_segment do
  transform Merge::ConstantValue, target: :data_source, value: 'source system'
end
~~~

This one uses plain Ruby to set up the transform class and calls its `:process` method on each row:

~~~
Kiba.job_segment do
  xform = Merge::ConstantValue.new(target: :data_source, value: 'source system')
  transform{ |row| xform.process(row) }
end
~~~

The second one might be useful in situations when you are trying to set things up more flexibly.

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
