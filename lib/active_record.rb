module ActiveRecord
  
  module AttributeMethods
    module ClassMethods
      # Prevent automatic definition of cloaked_attr getter, setter, query
      # methods by AR::B
      old_instance_method_already_implemented = instance_method(:instance_method_already_implemented?)
      define_method :instance_method_already_implemented? do |method_name|
        return true if self.cloaked_attr_methods.include?(method_name)
        old_instance_method_already_implemented.bind(self).call(method_name)
      end
    end
  end
  
  class Base
    # Prevent getter, setter, query behavior for cloaked_attr through
    # method_missing
    alias old_method_missing method_missing
    def method_missing(method_id, *args, &block)
      # For some reason, super from here gets AR::B, so we have to explicitly
      # call method_missing on AR::B.superclass
      if self.class.cloaked_attr_methods.include?(method_id.to_s)
        return ActiveRecord::Base.superclass.method_missing(method_id, *args, &block)
      end
      old_method_missing(method_id, *args, &block)
    end
    
    # Allow easy listing of getter, setter, and query method names for all
    # cloaked_attrs
    def self.cloaked_attr_methods
      hmethods = []
      cloaked_attrs.each do |attr|
        hmethods += [attr, "#{attr}=", "#{attr}?"]
      end
      hmethods
    end
    
    def self.cloaked_attrs
      inheritable_attributes[:cloaked_attrs] ||= []
    end
    
    # Allow definition of cloaked_attr
    def self.attr_cloaked(*attrs)
      attrs.each{|attr| cloaked_attrs << attr.to_s}
    end
    
    def self.attr_uncloaked(*attrs)
      attrs.each{|attr| cloaked_attrs.delete(attr.to_s)}
    end
  end
end
