# Kiba::Extend

Kiba is a [Data processing & ETL framework for Ruby](https://github.com/thbar/kiba).

kiba-extend is a suite of extensions useful in transformations and reshaping data in migrations. 

[mimsy-to-cspace](https://github.com/lyrasis/mimsy-to-cspace) is a publicly available example of `kiba-extend` usage.

Current projects in the Lyrasis `migrations-private` repo reflect my preferred practices for structuring Kiba-based projects, which have changed since the project that resulted in the current iteration of `mimsy-to-cspace`. See list below for some links to specific interesting/relatively unusual examples of use. 

To get a full overview of available transformations and what they do, run `rake spec` from the repo base directory. This will give you the names of all the transformations in `kiba-extend` and brief descriptions of what they do. 

For more clarity about exactly what each transformation does, if it is not described in the documentation yet, check the actual test files in `/spec/kiba/extend/transforms`.

## Examples

If the links below do not work, look for the same path in the archived projects folder.

- Use plain-old Ruby to [iterate through all files in a directory, process them the same way](https://github.com/lyrasis/fwm-cspace-migration/blob/e05e632545fbfe772d37afa7e230cacf1ebd9fd8/lib/fwm/authority_export.rb#L28-L34), and then [merge them](https://github.com/lyrasis/fwm-cspace-migration/blob/e05e632545fbfe772d37afa7e230cacf1ebd9fd8/lib/fwm/authority_export.rb#L73-L77).

I am working on better documentation for the transformations included in `kiba-extend`, which will be available at https://lyrasis.github.io/kiba-extend/
