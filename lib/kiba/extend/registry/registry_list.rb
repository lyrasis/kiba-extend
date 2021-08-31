# frozen_string_literal: true

module Kiba
  module Extend
    class RegistryList
      def initialize(*args)
        puts ''
        list = args.empty? ? Kiba::Extend.registry.entries : args.flatten
        list.each { |entry| puts entry.summary }
      end
    end
  end
end
