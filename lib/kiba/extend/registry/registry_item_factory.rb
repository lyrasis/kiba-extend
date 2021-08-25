require 'dry-container'

require_relative 'file_registry_entry'

class RegistryItemFactory < Dry::Container::Item::Factory
  def call(item, options = {})
    entry = Kiba::Extend::FileRegistryEntry.new(item)
    options[:memoize] ? Memoizable.new(entry, options) : Callable.new(entry, options)
  end
end
