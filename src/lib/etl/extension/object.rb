#!/usr/bin/env ruby

require 'rubygems'

#TODO: split this file up into collections, io, kernel/core and whatever....

class Object
    def db_nil?
        false
    end
end

#class NilClass
#    def nil_or_empty?
#        return true
#    end
#end
