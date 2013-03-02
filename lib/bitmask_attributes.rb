require 'bitmask_attributes/definition'
require 'bitmask_attributes/value_proxy'
require 'bitmask_attributes/definition_for_index'

module BitmaskAttributes
  extend ActiveSupport::Concern

  module ClassMethods
    def bitmask(attribute, options={multi:false}, &extension)
      if options[:multi] then
        bitmask_definitions[attribute] = Definition.new(attribute, options[:as], &extension)
      else
        if defined?(Rails) && Rails.configuration.cache_classes || !model.table_exists?
        else
          if not self.columns.detect { |col| col.name == attribute.to_s }
            raise ArgumentError, "`#{attribute}' is not an attribute of `#{self}'"
          end
        end  
        
        if not options[:as].try(:kind_of?,Array)
          raise ArgumentError, "Must provide an Array :as option"
        end
        # must be unique, and Array.size < 99 and values must be same type?
        if options[:default].present? then
          unless options[:default_raw] = options[:as].find_index(options[:default])
            raise ArgumentError, "default value #{options[:default]} is wrong value"
          end
        end        
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

    def bitmask_for_override
      # respond_to?
      @bitmask_definitions = superclass.bitmask_definitions.clone
      #@bitmasks = superclass.bitmasks.clone
    end

  end

end

ActiveRecord::Base.send :include, BitmaskAttributes

