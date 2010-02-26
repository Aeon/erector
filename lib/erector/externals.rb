module Erector
  module Externals
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      def depends_on(*args)
        x = Dependency.new(*args)
        push_dependency(x)
      end

      def push_dependency(x)
        if x.is_a? Dependency
          @externals ||= []
          @externals << x unless @externals.include?(x)
        else
          raise "expected Dependency, got #{x.class}: #{x.inspect}"
        end
      end

      # deprecated in favor of #depends_on
      def external(type, value, options = {})
        @externals ||= []
        type = type.to_sym
        x = Dependency.new(type, value, options)
        @externals << x unless @externals.include?(x)
      end

      # returns all externals of the given type from this class and all its
      # superclasses
      def externals(type)
        @externals ||= []

        type = type.to_sym
        parent_externals =
            if superclass.respond_to?(:externals)
              superclass.externals(type)
            else
              []
            end

        my_externals = @externals.select do |external|
          external.type == type
        end

        (parent_externals + my_externals).uniq
      end
    end

    def render_with_externals(options_to_external_renderer = {})
      output = Erector::Output.new
      self.to_s(:output => output)
      nested_widgets = output.widgets.to_a
      externals = ExternalRenderer.new({:classes => nested_widgets}.merge(options_to_external_renderer)).to_s(:output => output)
      output.to_a
    end

    def render_externals(options_to_external_renderer = {})
      output_for_externals = Erector::Output.new
      nested_widgets = output.widgets
      externalizer = ExternalRenderer.new({:classes => nested_widgets}.merge(options_to_external_renderer))
      externalizer._render(:output => output_for_externals)
      output_for_externals.to_a
    end
  end
end
