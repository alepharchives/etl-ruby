#!/usr/bin/env ruby
 
require 'rubygems'

class Hash
       
    alias_method :extract, :[]
    
    #TODO: figure out why this don't work!? :P
    
#    def []( key )
#        return extract(key) unless self.callable?
#        value = extract( key )
#        if value.kind_of? Hash
#            make_hash_callable value
#        end
#        value
#    end
    
    def semantic_eql?( other )
        self.each_pair { |key, value|  
            return false unless other.has_key?( key ) && other[ key ] == value
        }
        return true
    end
end