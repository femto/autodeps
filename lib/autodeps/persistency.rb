module Autodeps
  module Persistency
    class Mapping
      attr_accessor :dependent, :key_mapping, :value_mapping
      def initialize(dependent, key_mapping, value_mapping)
        @dependent = dependent
        @key_mapping = key_mapping
        @value_mapping = value_mapping
      end
    end
    def self.included(base)
      super
      base.extend(ClassMethods)
    end

    module ClassMethods
      def depend_on(clazz, options={})
        clazz = Object.const_get(clazz) if clazz.is_a?(String)
        options[:key_mapping] ||= {:id => (clazz.name.underscore.gsub(/^.*\//,"") + "_id").to_sym}
        class << clazz
          attr_accessor :_deps, :_autodeps_after_save_callbacked
        end
        clazz._deps ||= {}

        # options[:value_mapping].keys.sort?
        (clazz._deps[options[:value_mapping].keys.sort] ||= []) << Mapping.new(self, options[:key_mapping], options[:value_mapping] )

        Autodeps.autorun do

        end

        # if !self._autodeps_self_after_create_callbacked
        #   self._autodeps_self_after_create_callbacked = true
        #   self.send(:after_create) do
        #     Mapping.new(self, options[:key_mapping], options[:value_mapping] )
        #
        #   end
        # end

        if !clazz._autodeps_after_save_callbacked
          clazz._autodeps_after_save_callbacked = true
          clazz.send(:after_save) do
            clazz._deps.each do |attribute_keys, values|
              if attribute_keys.any? {|attribute_key| self.send("#{attribute_key.to_s}_changed?")}
                values.each do |mapping|
                  relation = mapping.dependent
                  mapping.key_mapping.each do |source_key, target_key|
                    relation = relation.where(target_key => self.send(source_key))
                  end

                  relation.each do |tuple|
                    mapping.value_mapping.each do |source_key, target_key|
                      tuple[target_key] = self.send(source_key)
                    end
                    tuple.save
                  end
                end
              end
            end

          end
        end
      end
    end
  end
end