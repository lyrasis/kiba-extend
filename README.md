# Kiba::Extend

Kiba is a [Data processing & ETL framework for Ruby](https://github.com/thbar/kiba).

kiba-extend is a suite of extensions useful in transformations and reshaping data in migrations. 

[mimsy-to-cspace](https://github.com/lyrasis/mimsy-to-cspace) is a publicly available example of `kiba-extend` usage.

Current projects in the Lyrasis `migrations-private` repo reflect my preferred practices for structuring Kiba-based projects, which have changed since the project that resulted in the current iteration of `mimsy-to-cspace`.

I am working on better documentation for the transformations included in `kiba-extend`, which is available at https://lyrasis.github.io/kiba-extend/

To get a full overview of available transformations and what they do, run `rake spec` from the repo base directory. This will give you the names of all the transformations in `kiba-extend` and brief descriptions of what they do. 

For more clarity about exactly what each transformation does, if it is not described in the documentation yet, check the actual test files in `/spec/kiba/extend/transforms`.
