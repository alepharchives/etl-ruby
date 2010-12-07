#!/usr/bin/env ruby
 
require 'rubygems'

# Expands on the default ruby Binding class.
# The idea for these extensions was stolen from Facets, 
# but this really is our own implementation.
class Binding

    ReceiverMatchPattern = /(method)|(local|instance|class)(?:[-\s]{1})(variable)/

    # Returns the local variables defined in the binding context
    #
    #   a = 2
    #   binding.local_variables  #=> ["a"]
    #
    def local_variables()
        eval( 'local_variables', self )
    end

    # Evaluates the supplied 'code' in the given context
    def evaluate( code )
        Kernel.eval( code, self )
    end

    # Is 'thing' defined?
    def def?( thing )
        !evaluate( "defined? #{thing}" ).nil?
    end

    # What is 'thing' defined as?
    def defined?( thing )
        evaluate( "defined? #{thing}" )
    end

    # Who was 'self' in the original context?
    def meta_self
        evaluate( 'self' ) #.class.methods or instance_methods...
    end

    # Evaluates the supplied block in the original context! 
    # Can (optionally) pass #meta_self in to the supplied block.
    # Can also 'magically' resolve local variable names, like so:
    # 
    # def example( msg )
    #     return binding 
    # end
    # 
    # example( 'foo' ).scope_eval { puts msg }
    # 
    # # output: 'foo'
    def scope_eval( &block )
        #instance_eval( &block )
        meta_self.class.module_eval do
            attr_accessor :__binding_context
            def method_missing( sym, *args )
                unless __binding_context.nil?
                    @__binding_context.method_missing( sym, *args )
                end
            end
        end
        meta_self.__binding_context = self
        begin
            if block.arity != 0
                block.call( meta_self )
            else
                block.call
            end
        ensure
            meta_self.class.module_eval do
                undef_method :__binding_context
                undef_method :__binding_context=
                remove_method :method_missing
            end
            meta_self.send(:instance_variable_set, "@__binding_context", nil)
        end

    end

    def method_missing( sym, *args )
        local = lookup_local_variable( sym )
        return local unless local.nil?
        #  "#{receiver}.send( sym, *_id2ref( #{args.object_id} ) )"
        super
    end

    private

    def lookup_local_variable( sym )
        return nil unless evaluate( "defined? #{sym}" ) =~ /local-variable/
        evaluate( sym.to_s )
    end

    #def receiver( sym )
    #    receiver_class = meta_self.class
    #    return 'self' if defined?( sym ) == 'method'
    #
    #    end
    #end

end
