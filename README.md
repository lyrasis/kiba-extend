# Kiba::Extend

Kiba is a [Data processing & ETL framework for Ruby](https://github.com/thbar/kiba).

kiba-extend is a suite of extensions useful in transformations and reshaping data in migrations. 

[mimsy-to-cspace](https://github.com/lyrasis/mimsy-to-cspace) is a publicly available example of kiba-extend usage.

Current projects in the Lyrasis `migrations-private` repo will reflect my preferred practices for structuring Kiba jobs, which may have changed since the project that resulted in the current iteration of `mimsy-to-cspace`.

There's no time to write up nice documentation for this, so the easiest way to get a sense of the available extensions is to run `rake spec` from the repo base directory. 

That will give you the names of all the transformations in `kiba-extend` and hopefully a vague sense of what they do. 

For more clarity about what each transformation does, check the actual test files in `/spec`. I try to write the tests so that I can go back later and look at them to remind myself of what each thing does. 
