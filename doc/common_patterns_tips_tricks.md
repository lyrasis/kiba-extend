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

It could also useful in project-specific transforms as shown below (need to test that this actually works):


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
    row = xform.process(row)
    # do more stuff to row
  end
  
  private
  
  attr_reader :param1, :param2, :otherxform
end
```
