#!/usr/bin/env ruby

require 'rubygems'

# I provide validation behaviour, which can be consumed statically,
# or mixed in (as with any other module).
module Validation

    # Enforces the presense of all supplied options in the specified hash_instance.
    # Raises ArgumentError for any that are missing from the hash_instance.
    def require_entries_for( hash_instance, *options )
        options.each do |option|
            raise ArgumentError, "option #{option} is required" unless hash_instance.has_key? option.to_sym
        end
    end

    def missing?( *items )
        items.each { |item| return true if item.nil? }
        false
    end

    protected

    def coalesce( input, nil_string )
        input || nil_string
    end

    def coalesce_empty( input, nil_string )
        return nil_string if input.respond_to?( :empty? ) && input.empty?
        return coalesce( input, nil_string ) if input.nil?
        return input
    end

    # Validates the local variables in the supplied #Binding context (see
    # #Kernel#binding for more details), raising an #ArgumentError if any
    # is nil. 
    # You can optionally specify the names of the local variables you wish to
    # validate, in which case only these are checked against the supplied #Binding.
    def validate_arguments( binding_context, *names )
        names.collect! { |item| item.to_s }
        target_args = proc { |name| ( (n=*names).nil? || names.include?( name ) ) ? true : false }
        binding_context.local_variables.each do |var_name|
            if target_args.call( var_name ) && binding_context.evaluate( var_name ).nil?
                raise ArgumentError, message="the '" + var_name.gsub( /_/, ' ') + "' argument cannot be nil", caller
            end
        end
    end

    # Validates the presense of the named instance variables (as supplied in
    # the 'names' parameter) against the supplied #Binding context. 
    # If a block is supplied, this will be used to handle nil (or undefined)
    # values, otherwise the default handler will raise an #InvalidOperationException.
    #
    # Example:
    #<code>
    # class Foo
    #   attr_accessor :name
    #   def example()
    #       validate_instance_variables( :name ) do |field_name|
    #           raise StandardError, 
    #               "was expecting '#{field_name}' to be set, but it wasn't!", caller
    #       end
    #   end
    # end
    #</code>
    def validate_instance_variables( binding_context, *names, &block )
        handler = ( block ) ? block : method( :invalid_state )
        names.each do |field_name|
            unless binding_context.evaluate( "@#{field_name}" )
                handler.call( field_name )
            end
        end
    end
    
    # Validates that the supplied environment is one of the recognised environments 
    def valid_environment( environment_name )
        environment_name ||= :INVALID
        unless [ :production, :sandbox ].include? environment_name.to_sym
            raise ArgumentError,"the 'environment_name' must be a known environment", caller
        end
    end

    private
    def invalid_state( field_name )
        raise InvalidOperationException.new(
            ( message = "'#{field_name.to_s.gsub( /_/, ' ' )}' not set" )
        ), message, caller
    end

end
