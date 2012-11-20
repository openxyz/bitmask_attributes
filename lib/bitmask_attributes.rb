require 'bitmask_attributes/definition'
require 'bitmask_attributes/value_proxy'
require 'bitmask_attributes/definition_for_index'

module BitmaskAttributes
  extend ActiveSupport::Concern

  module ClassMethods
    def bitmask(attribute, options={multi:false}, &extension)
      # The model cannot be validated if it is preloaded and the attribute/column is not in the
      # database (the migration has not been run) or table doesn't exist. This usually
      # occurs in the 'test' and 'production' environment or during migration.
      if defined?(Rails) && Rails.configuration.cache_classes || !self.table_exists?
      else
        unless self.columns.detect { |col| col.name == attribute.to_s }
          raise ArgumentError, "`#{attribute}' is not an attribute of `#{self}'"
        end

        unless options[:as] && options[:as].kind_of?(Array)
          raise ArgumentError, "Must provide an Array :as option"
        end
        # must be unique, and Array.size < 99 and values must be same type?
        if not options[:default].nil? then
          unless options[:default_raw] = options[:as].find_index(options[:default])
            raise ArgumentError, "default value #{options[:default]} is wrong value"
          end
        end
      end

      if options[:multi] then
        bitmask_definitions[attribute] = Definition.new(attribute, options[:as], &extension)
      else
        bitmask_definitions[attribute] = DefinitionForIndex.new(attribute, options, &extension)
      end
      bitmask_definitions[attribute].install_on(self)
    end

    def bitmask_definitions
      @bitmask_definitions ||= {}
    end

    def bitmasks
      @bitmasks ||= {}
    end
  end
end

ActiveRecord::Base.send :include, BitmaskAttributes

