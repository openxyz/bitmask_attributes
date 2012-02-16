module BitmaskAttributes
  class DefinitionForIndex 
    attr_reader :attribute, :values, :extension
    
    def initialize(attribute, values=[], &extension)
      @attribute = attribute
      @values = values
      @extension = extension
    end
    
    def install_on(model)
      #validate_for model
      #generate_bitmasks_on model
      override model
      #create_convenience_class_method_on model
      #create_convenience_instance_methods_on model
      create_scopes_on model
      create_attribute_methods_on model
    end
    
    private

      def validate_for(model)
        # The model cannot be validated if it is preloaded and the attribute/column is not in the
        # database (the migration has not been run) or table doesn't exist. This usually
        # occurs in the 'test' and 'production' environment or during migration.
        return if defined?(Rails) && Rails.configuration.cache_classes || !model.table_exists?
       
        unless model.columns.detect { |col| col.name == attribute.to_s }
          raise ArgumentError, "`#{attribute}' is not an attribute of `#{model}'"
        end
      end
    
      def generate_bitmasks_on(model)
        model.bitmasks[attribute] = HashWithIndifferentAccess.new.tap do |mapping|
          values.each_with_index do |value, index|
            mapping[value] = index
          end
        end
      end
    
      def override(model)
        override_getter_on(model)
        override_setter_on(model)
      end
    
      def override_getter_on(model)
        model.class_eval %(
          def #{attribute}            
            @#{attribute} ||= self.class.bitmask_definitions[:#{attribute}].values[( self[:#{attribute}] || -1)]
          end
        )
      end
    
      def override_setter_on(model)
        model.class_eval %(
          def #{attribute}=(raw_value)            
            self[:#{attribute}] = self.class.bitmask_definitions[:#{attribute}].values.find_index(raw_value) || -1
          end
        )
      end
    
      # Returns the defined values as an Array.
      def create_attribute_methods_on(model)
        model.class_eval %(
          def self.values_for_#{attribute}      
            self.bitmask_definitions[:#{attribute}].values                   
          end                                   
        )
      end
    
      def create_convenience_class_method_on(model)
        model.class_eval %(
          def self.bitmask_for_#{attribute}(*values)
            values.inject(0) do |bitmask, value|
              unless (bit = bitmasks[:#{attribute}][value])
                raise ArgumentError, "Unsupported value for #{attribute}: \#{value.inspect}"
              end
              bitmask | bit
            end
          end
        )
      end

      def create_convenience_instance_methods_on(model)
        values.each do |value|
          model.class_eval %(
            def #{attribute}_for_#{value}?                  
              self.#{attribute}?(:#{value})
            end
          )
        end
        model.class_eval %(
          def #{attribute}?(*values)
            if !values.blank?
              values.all? do |value|
                self.#{attribute}_array.include?(value)
              end
            else
              self.#{attribute}_array.present?
            end
          end
        )
      end
    
      def create_scopes_on(model)
        model.class_eval %(        
          scope :with_#{attribute},
            proc { |value| 
              if value
                mask = self.bitmask_definitions[:#{attribute}].values.find_index(value)
                where('#{attribute} =  ?', mask )
              else
                where("#{attribute} >= 0 ")
              end              
            }                    
       
          scope :without_#{attribute}, 
            proc { |value| 
              if value
                mask = self.bitmask_definitions[:#{attribute}].values.find_index(value)
                where('#{attribute} <>  ?', mask )
              else
                where("#{attribute} IS NULL OR #{attribute} < 0 ")
              end              
            }        
        )
      end
    end
end