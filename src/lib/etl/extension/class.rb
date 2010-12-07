#!/usr/bin/env ruby

require 'rubygems'

class Class

    # Stolen (the idea) shamelessly from facets (http://facets.rubyforge.org),
    # although this is not a cut & paste copy!
    #
    # Automatically create an initializer assigning the given
    # arguments.
    #
    # The initializer will not raise an Exception when the user
    # does not supply a value for each instance variable. In that
    # case it will just set the instance variable to nil. You can
    # assign default values or raise an Exception in the block.
    #
    def initialize_with( *attributes, &block )
        raise ArgumentError, 'named arguments are not supported', caller if attributes.first.kind_of? Hash
        if attributes.last.kind_of? Hash
            options = attributes.pop
            validate_initializer_arguments = ( options[ :validate ] )
            options.delete( :validate )
        else
            options = {}
        end
        options.each do |opt, enabled|
            module_eval( "#{opt} #{attributes.collect { |attr| attr.inspect }.join( ', ' )}" ) if enabled
        end
        define_method( :initialize ) do |*args|
            unless args.size.eql?(attributes.size)
                raise ArgumentError, "wrong number of arguments (#{args.size} for #{attributes.size})", caller
            end
            attributes.zip( args ) do |sym, value|
                if validate_initializer_arguments
                    raise ArgumentError, "the '" + sym.to_s.gsub( /_/, ' ') + "' argument cannot be nil", caller unless value
                end
                instance_variable_set( "@#{sym}", value )
            end
            instance_eval( &block ) if block
        end
    end

end
