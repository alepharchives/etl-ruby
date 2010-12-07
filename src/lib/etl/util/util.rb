#!/usr/bin/env ruby

require 'rubygems'

# I am raised by code whose invariants have been violated; such as an interaction
# with an object whose state is invalid - although this isn't the only case, hence
# the choice of name.
# = What this means to you, the developer!
# This means, whenever you violate the implicit assumptions of a programmatic API,
# I could rear my *ugly* head! *Muuh Ha ha ha* [ evil laughter trails off to a distance! ]. :P <-t4->
class InvalidOperationException < StandardError
end

# I am raised by code which doesn't support an operation that you're trying to call!
class UnsupportedOperationException < StandardError
end

#
# Makes 'hash' callable (e.g. you can access it via property syntax
# instead of hash[key]) -> all the original rules/behaviours apply.
#
def make_hash_callable( hash )
    hash.instance_eval do

        def method_missing( method_name, *args )
            usable_key = usable_key_for_method_name? method_name
            value = self[ usable_key ]
            if value.kind_of? Hash
                make_hash_callable value
            end
            return value unless usable_key.nil?
            super
        end

        def usable_key_for_method_name?( method_name )
            if self.has_key? method_name
                return method_name
            elsif self.has_key? method_name.to_sym
                return method_name.to_sym
            elsif self.has_key? method_name.to_s
                return method_name.to_s
            end
            nil
        end

        def respond_to?( method_name )
            return true if super or usable_key_for_method_name? method_name
            false
        end
        
    end
end
