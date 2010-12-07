#!/usr/bin/env ruby

require 'rubygems'

class Array

    #todo: use the natural language support classes from rails and do this dynamically instead,
    #       so you can get arr = [ 1, 2, 3, 4 ]; arr.first + arr.second + arr.third + arr.fourth #etc...

    # Returns the second element in the array
    def second
        return nil unless self.size > 1
        self[1]
    end
    
end