require 'bitmask_attributes/definition'
require 'bitmask_attributes/value_proxy'
require 'bitmask_attributes/definition_for_index'        

module BitmaskAttributes
  extend ActiveSupport::Concern
  
  module ClassMethods
    def bitmask(attribute, options={multi:false}, &extension)
      unless options[:as] && options[:as].kind_of?(Array)
        raise ArgumentError, "Must provide an Array :as option"
      end
      if options[:multi] then
        bitmask_definitions[attribute] = Definition.new(attribute, options[:as].to_a, &extension)
      else
        bitmask_definitions[attribute] = DefinitionForIndex.new(attribute, options[:as].to_a, &extension)
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
