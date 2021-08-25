require_relative 'registry_item_factory'

class CustomRegistry < Dry::Container::Registry
  def factory
    @factory ||= Kiba::Extend::RegistryItemFactory.new
  end
end
