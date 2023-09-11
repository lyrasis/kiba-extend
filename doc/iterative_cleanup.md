# Using the iterative cleanup mixin

"Iterative cleanup" means the client may provide the worksheet more
than once, or that you may need to produce a fresh worksheet for the
client after a new database export is provided.

There is no reason you can't use the pattern for expected one-round
cleanup. How often does one round of cleanup turn into more, after
all?

## Examples

[kiba-extend-project](https://github.com/lyrasis/kiba-extend-project)
has been updated to reflect usage of the `IterativeCleanup` mixin.

Refer to todo:link Kiba::Tms::AltNumsForObjTypeCleanup as an example config
  module extending this mixin module in a simple way. See
  todo:link Kiba::Tms::PlacesCleanupInitial for a more complex usage with
  default overrides and custom pre/post transforms.

## Project setup assumptions

Your project must follow some setup/configuration conventions in order
  to use this mixin:

### Each cleanup process must be configured in its own config module

A config module is a Ruby module that responds to `:config`.

Extending `Dry::Configurable` adds a `config` method to a module:

```ruby
module Project::NameCategorization
  module_function
  extend Dry::Configurable
end
```

Or you can manually define a `config` class method on the module:

```ruby
module Project::PersonCleanup
  module_function

  def config
    true
  end
end
```

### `Kiba::Extend` `config_namespaces` setting must be set from your project

After your project's base file has called the project's `loader`, it
must set the `Kiba::Extend.config.config_namespaces` setting.

This setting lists the namespace(s) where your config modules live.

In most of my projects, all of my config modules are in one namespace.
For example, for the above project, I would add:

```ruby
Kiba::Extend.config.config_namespaces = [Project]
```

Note that the
setting takes an array, so you can list multiple namespaces if you
have organized your project differently and your configs are not all
in one namespace. For example, a migration for a Tms client may have
client specific cleanups in the client-specific migration code
project (config namespace: `TmsClientName`). That code project will
make use of the kiba-tms application, which also defines cleanup
configs in the namespace `Kiba::Tms`. Such a project would do this
at the bottom of `lib/tms_client_name.rb`:

```ruby
Kiba::Extend.config.config_namespaces = [Kiba::Tms, TmsClientName]
```

### Add cleanup job registration to your `RegistryData` registration method

Add the following to `RegistryData.register` (or whatever method
triggers the registration of all your jobs):

```ruby
Kiba::Extend::Utils::IterativeCleanupJobRegistrar.call
```

This line should be added before any `registry.transform`,
`registry.freeze`, or `registry.finalize` methods.

### `config_namespaces` setting is populated before `RegistryData` registration

Calling `RegistryData.register` (or whatever method triggers the
registration of all your jobs) must be done ***after*** the
`config_namespaces` are set.
