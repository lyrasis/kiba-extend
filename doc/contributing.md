# Contributing to `kiba-extend`

The preferred code, documentation, and testing practices have evolved over time and have not all been retrospectively updated throughout the codebase.

This can be confusing, so this page's purpose is to point you to the current preferred patterns for new code contributions.

**The focus is on code for transforms**

## Code structure

Transforms go in `lib/kiba/extend/transforms`.

### If creating a new transform namespace

* Create a new `.rb` file in `lib/kiba/extend/transforms` to document the scope of the namespace and alias the namespace (so you don't have to type out `Kiba::Extend::Transforms` for every transform used in a pipeline/job.) See [`name.rb`](https://github.com/lyrasis/kiba-extend/blob/main/lib/kiba/extend/transforms/name.rb) as an example.
  * Note: If a namespace includes similar transforms, this is an appropriate place to differentiate them. See the `Deduplicate` transform namespace [code](https://github.com/lyrasis/kiba-extend/blob/main/lib/kiba/extend/transforms/deduplicate.rb) and [documentation page](https://lyrasis.github.io/kiba-extend/Kiba/Extend/Transforms/Deduplicate.html)
* Create a directory to hold the transforms that will be in the new namespace. See [`name` directory](https://github.com/lyrasis/kiba-extend/tree/main/lib/kiba/extend/transforms/name) as an example.

### New transforms

Each transform class is in its own separate file in its namespace directory.

Transforms must be implemented following [the requirements for `kiba` ETL transforms](https://github.com/thbar/kiba/wiki/Implementing-ETL-transforms).

See the "Patterns in Transforms" section below for more best practices.

## Documentation

Include [YARD documentation comments](https://www.rubydoc.info/gems/yard/file/docs/GettingStarted.md) in your code. This is what creates/publishes the automatically generated [`kiba-extend` documentation site](https://lyrasis.github.io/kiba-extend/) when a pull request is merged or a commit is made directly to the main branch.

NOTE: `kiba-extend` uses a Markdown parser to convert YARD to HTML

Most important:

* Brief description of what the transform does (first line of transform class documentation)
* If relevant: Distinguish between other transforms that do something similar. This can be done [in an individual transform's documentation](https://github.com/lyrasis/kiba-extend/blob/main/lib/kiba/extend/transforms/deduplicate/table.rb) and/or [at the transform namespace level](https://github.com/lyrasis/kiba-extend/blob/main/lib/kiba/extend/transforms/deduplicate.rb)
* Optional: Fuller description of anything about the transform's behavior that may not be obvious/apparent
* Usage example(s) showing input data, how transform is set up in pipeline/job definition code, and result. **Important:** See also the Testing section.
* Document each parameter for `initialize`. See the [YARD Getting Started Guide section on declaring types](https://www.rubydoc.info/gems/yard/file/docs/GettingStarted.md#declaring-types) for an intro. The [interactive YARD Type Parser](https://yardoc.org/types.html) is helpful for checking that your type declarations will work as expected.
* If your transform returns the typical Hash row (with Symbol keys as field names and Strings/NilValues as values), the `:process` method should be documented as:

~~~
# @param row [Hash{ Symbol => String, nil }]
~~~

If you include a `:close` method (See [kiba wiki: Implementing ETL Transforms](https://github.com/thbar/kiba/wiki/Implementing-ETL-transforms)), it is assumed it returns yielded rows. No doc comments necessary.

Private methods do not need to be documented.

### Testing your YARD doc
YARD is installed as a development dependency, so I think if you `bundle install` in your local copy of kiba-extend, you get it.

`cd` into the base directory of the `kiba-extend` repo. Then:

~~~
yard server -rd
~~~

This should spin up a daemonized copy of of the documentation site at http://localhost:8808/

Reloading a page should re-parse the documentation.

When done, do the following to find the YARDDOC DAEMON process using the tcp port and kill it:

~~~
lsof -wni tcp:8808
kill -9 {pid}
~~~

## Tests

Tests are in RSpec.

Contributed code should be well-tested. After running `bundle exec rspec` (or just `rspec` if you have binstubbed it), open `/kiba-extend/coverage/index.html` to verify test and [branch coverage](https://www.tutorialspoint.com/software_testing_dictionary/branch_testing.htm) of your code.

### Test transforms in their documentation using yardspec

As of September 2022, the plan is to move most tests for transforms into `@example` tags in the YARD doc comments in the actual transform classes. See [`Prepend::ToFieldValue`](https://github.com/lyrasis/kiba-extend/blob/main/lib/kiba/extend/transforms/prepend/to_field_value.rb).

This will make for slightly less pretty documentation pages, but has big benefits:

* ensures documentation does not get out of step with actual behavior of code (HUGE)
* reduce duplication/tedious reformatting between `/spec` files and YARD comments in transforms
* forces structuring tests in a way that fully demonstrates the function of a transform

### Tests that require changing `Kiba::Extend.config` settings

If you want to future-proof tests relying on config settings against future changes to the default values of those settings, then explicitly setting the config values in your tests is a great idea. However, that hasn't been done consistently to date.

Changing a setting value in one test can cause problems in other tests if values are not reset to default.

Note that running tests in a random order is a recommended practice, in order to ensure you are not getting false positives due to state effects in your tests that are not present in real life. If you have not been careful that any config changes made for one test are reverted, mayhem can ensue later if you turn on randomness in the test suite.

`Kiba::Extend`'s config settings are powered by `dry-configurable`, which offers [a test interface](https://dry-rb.org/gems/dry-configurable/main/testing/) to handle this.

This test interface is already set up in `kiba-extend`'s [`spec_helper.rb`](https://github.com/lyrasis/kiba-extend/blob/main/spec/spec_helper.rb), so if you are writing full-fledged RSpec tests in the `/spec` directory, you can do as shown there (though, resetting *after* each test which may tweak the config seems to make more sense?)

If you are writing yardspec tests, you can do the following:

~~~
# @example With `multival: true` and no :sep
#   Kiba::Extend.config.delim = ';'
#   xform = Clean::RegexpFindReplaceFieldVals.new(
#     fields: :val,
#     find: 's$',
#     replace: '',
#     multival: true
#   )
#   input = [
#     {val: 'bats;bats'}
#   ]
#   result = input.map{ |row| xform.process(row) }
#   Kiba::Extend.reset_config
#   expected = [
#     {val: 'bat;bat'}
#   ]
#   expect(result).to eq(expected)
# @example With `multival: true` and no :sep
#   xform = Clean::RegexpFindReplaceFieldVals.new(
#     fields: :val,
#     find: 's$',
#     replace: '',
#     multival: true
#   )
#   input = [
#     {val: 'bats|bats'}
#   ]
#   result = input.map{ |row| xform.process(row) }
#   expected = [
#     {val: 'bat|bat'}
#   ]
#   expect(result).to eq(expected)
~~~

At the time of writing, the default value of `Kiba::Extend.delim` is `|`. The first test here sets the value of that setting to `;`. That test passes. Since we call `Kiba::Extend.reset_config` after getting the result in the first test, the second test passes. If we did not call `Kiba::Extend.reset_config` in the first test, the second test would fail because the default value is still `;`.

**Note: Do not write the above unnecessary tests of basically the exact same thing. 🤣 It's the clearest example of the need for the `:reset_command` method I can think of at the moment, though**

## Updating existing code

If you are touching existing code, please make sure it is up to date with the current practices outlined above in terms of code structure, documentation, and testing.

## Patterns in transforms

Some/most of these are NOT followed consistently throughout the existing code, but are aspirational guidelines.

If nothing else, `kiba-extend` is proof I have learned a lot since I started building it, for sure. Unfortunately much of the older code is inconsistent, overly complex, or worse. Very gradually some has been improved but there are still a lot of antipatterns in the codebase.

This section aims to clarify what the *desired* patterns are.

### `field` vs. `fields` parameter

Most transforms do a relatively simple thing to one or more fields, and require the target field(s) to be passed in.

Where possible, write such transforms so that they can be called on one or many fields with minimal typing. For example, both of the following work fine:

~~~
transform Delete::Fields, fields: %i[name title date]

transform Delete::Fields, fields: :title
~~~

The commonly used code pattern to support this is:

~~~
# @param fields [Array<Symbol>,Symbol] field(s) to delete from
def initialize(fields:)
  @fields = [fields].flatten
end
~~~

If it is a reasonable assumption that someone may want to apply the transform to **all** fields, consider `include`-ing [the `Allable` transform mixin module](https://lyrasis.github.io/kiba-extend/Kiba/Extend/Transforms/Allable.html). (See the code for "Included in" transforms at the top of that page)

### `delim` vs. `sep` parameters

Split/join strings have been passed into transforms inconsistently over time, but since mid 2020 (ish) I've been trying to standardize this.

Prefer `delim`

Over time, `sep` will be deprecated/replaced with `delim` where it still exists.

### Should a field be treated as multivalued or not?

In some earlier-added transforms such as `Clean::RegexpFindReplaceFieldVals`, there's a `:multival` **and** a `:delim` (or `:sep`) parameter. These tend to have overly complicated logic where, if `:delim` is not given and `multival: true`, the value of `Kiba::Extend.delim` is used for `:delim`, but if `multival: false`, then delim isn't used at all.

(I'm sure I thought this was useful or needed at the time, but I am not sure why... 😅)

Preferred practice when multivalued treatment should be turned off/on is to treat as multivalue if `:delim` is given, otherwise not.

So, if the default behavior should be multivalued:

~~~
def initialize(fields:, delim: Kiba::Extend.delim)
~~~

User can turn off multivalued treatment by passing `delim: nil`. User can pass non-default `:delim` value as well.

And if the default behavior should be to treat the whole field value as one string:

~~~
def initialize(fields:, delim: nil)
~~~

User can turn on multivalued treatment by passing a `:delim` value.

### Using `row.fetch` (or preferrably, not)

An empty CSV field by default comes through as `nil`, but some of the CSV converters provided by `kiba-extend` can end up converting a non-nil field value to an empty string.

Prior to realizing I should add an `activesupport` dependency to pull in [the `:blank?` method](https://guides.rubyonrails.org/active_support_core_extensions.html#blank-questionmark-and-present-questionmark), dealing with the fact that `row[:fieldname]` might return `nil` or an empty String was another thing I was dealing with in a somewhat over-complicated way with `row.fetch` used in more or less sensible ways.

In particular, my previous sometimes use of `row.fetch(:fieldname, nil)` is not a pattern to follow, as it is just saying "If row doesn't have fieldname as a key, return nil", which is what it is going to do anyway if you just call `row[:fieldname]`, [which is more performant](https://github.com/fastruby/fast-ruby/blob/main/code/hash/bracket-vs-fetch.rb).

### Complex transforms: compose behaviors by reusing other transforms

A simple example is [`Rename::Fields`](https://github.com/lyrasis/kiba-extend/blob/main/lib/kiba/extend/transforms/rename/fields.rb), which is just a multi-field wrapper around the pre-existing `Rename::Field`.

A more complex example is [`Collapse::FieldsToRepeatableFieldGroup`](https://github.com/lyrasis/kiba-extend/blob/main/lib/kiba/extend/transforms/collapse/fields_to_repeatable_field_group.rb), which combines a number of other transforms for a specific complex purpose.

### Extract reusable processing logic to command service objects

These object classes should more or less follow [the Command Pattern](https://www.alchemists.io/articles/command_pattern/). The linked article is very rigorous about what the pattern requires, but the main things are:

* The class should do one specific thing
* The class should have one public method: `:call`. When you call `:call`, the class does the thing and returns the result

There are many benefits to doing this, but one I've run into in the `kiba-tms` project is that sometimes you need to use this logic/behavior outside the context of a transform class that takes and return a row.

I have not been great at putting these in a consistent place. Some things I was using over and over again in transforms are in [`lib/kiba/extend/transforms/helpers/`](https://github.com/lyrasis/kiba-extend/tree/main/lib/kiba/extend/transforms/helpers), while some have been added to [`lib/kiba/extend/utils/`](https://github.com/lyrasis/kiba-extend/tree/main/lib/kiba/extend/utils).

Organization of these needs to be re-thought. For now, I'm thinking `lib/transforms/helpers` should be limited to those that take and return a row, while others can keep going in `lib/utils` for now.

## Making a pull request

Pull requests are welcome!

Please add entries in the "Unreleased" section of the CHANGELOG.adoc that describe your changes. In general we don't need to specify that tests were added or code was refactored in the CHANGELOG, since it primarily should reflect what users of `kiba-extend` need to know about its evolution.

Assign @kspurgin as a reviewer.
