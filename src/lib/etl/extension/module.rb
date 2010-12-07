#!/usr/bin/env ruby
 
require 'rubygems'

class Module

    alias mixin include

    #TODO: use this (see old .svn branch prior to 1.0 rel) or delete these...

    #class InitializerArgument
    #    attr_reader :name, :value
    #    def initialize( name, value )
    #        @name, @value = name, value
    #    end
    #    def to_arg_string
    #        #TODO: add a check for @value.respond_to? :to_sql
    #        return @name if @name == @value
    #        return "#{@name}=#{ @value.kind_of?( String ) ? @value : @value.inspect}"
    #    end
    #    def to_name_sym
    #        return ":#{@name.to_s}"
    #    end
    #    def to_assignment_statement
    #        return "@#{@name}=#{@name}"
    #    end
    #end
    #
    #class ArgumentList < Array
    #    attr_accessor :options
    #    def initializations
    #        return self.collect { |arg| arg.to_assignment_statement }
    #    end
    #    def method_signature
    #        self.collect { |arg| arg.to_arg_string }.join( ', ' )
    #    end
    #    def method_call
    #        self.collect { |arg| arg.name }.join( ', ' )
    #    end
    #    def named_symbols
    #        self.collect { |arg| arg.to_name_sym }.join( ', ' )
    #    end
    #end
    
    # Works like #attr_reader, but returns a frozen duplicate of
    # the underlying object (e.g. {target-object}.dup)
    def immutable_attr_reader(*names) 
        names.each do |name|
            define_method(name) do 
                instance_variable_get("@#{name}").dup.freeze
            end
        end
    end    

end
