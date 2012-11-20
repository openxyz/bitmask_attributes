module BitmaskAttributes
  class DefinitionForIndex
    attr_reader :attribute, :values,:default,:default_raw, :extension

    def initialize(attribute, options, &extension)
      @attribute = attribute
      @values = options[:as].to_a
      @default = options[:default]
      @default_raw = options[:default_raw]
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

      def override(model)
        override_getter_on(model)
        override_setter_on(model)
      end


      def override_getter_on(model)
        model.class_eval %(
          def #{attribute}
            unless @#{attribute} then
              definition = self.class.bitmask_definitions[:#{attribute}]
              if self[:#{attribute}]  then
                @#{attribute} = definition.values[self[:#{attribute}]]
              else
                @#{attribute} =  definition.default
              end
            end
            @#{attribute}
          end

          before_create do |m|
            self[:#{attribute}] ||= self.class.bitmask_definitions[:#{attribute}].default_raw
          end

        )
      end

      def override_setter_on(model)
        model.class_eval %(
          def #{attribute}=(raw_value)
            definition = self.class.bitmask_definitions[:#{attribute}]
            if raw_value.kind_of?(Integer) && raw_value.between?(0,definition.values.size - 1) then
              temp = raw_value
            else
              temp = definition.values.find_index(raw_value)
            end
            self[:#{attribute}] = temp if temp
            #{attribute}
          end
        )
      end

      # Returns the defined values as an Array.
      def create_attribute_methods_on(model)
        #model.class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
        model.class_eval %(
          def self.values_for_#{attribute}
            self.bitmask_definitions[:#{attribute}].values
          end

          def self.values_with_bitmask_for_#{attribute}
            ret = []
            self.bitmask_definitions[:#{attribute}].values.each_with_index{|v,k| ret.push [v,k]}
            ret
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
                mask = value.kind_of?(Integer) ? value : self.bitmask_definitions[:#{attribute}].values.find_index(value)
                where('#{attribute} =  ?', mask )
              else
                where("#{attribute} >= 0 ")
              end
            }

          scope :without_#{attribute},
            proc { |value|
              if value
                mask = value.kind_of?(Integer)  ? value : self.bitmask_definitions[:#{attribute}].values.find_index(value)
                where('#{attribute} <>  ?', mask )
              else
                where("#{attribute} IS NULL OR #{attribute} < 0 ")
              end
            }
        )
      end
    end
end

