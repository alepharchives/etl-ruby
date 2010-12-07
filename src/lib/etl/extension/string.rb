#!/usr/bin/env ruby

require 'rubygems'

class String

    public

    # A empty string!
    #
    Empty = ""

    def remove_all(pattern)
        return self.gsub(pattern, '')
    end
    
    def String.nil_or_empty?(string)
        return string.nil? || string.size.eql?(0)
    end

    alias - remove_all


    # By default, converts to UpperCamelCase. If the argument to camelize
    # is set to ":lower" then camelize produces lowerCamelCase.
    #
    # camelize will also convert '/' to '::' which is useful for converting paths to namespaces
    #
    def camelize( option=nil )
        if option == :lower
            String.string_camelize(self, false)
        else
            String.string_camelize(self)
        end
    end

    # A hook method to make DSL expression evaluation easier for consumers to manage.
    def evaluate(exchange)
        return self
    end

    def first
        self[0..0]
    end

    def last
        last_index = size - 1
        self[last_index..last_index]
    end

    def starts_with? other
        return self[0...other.size] == other
    end

    def ends_with? other
        return self.reverse[0...other.size] == other.reverse
    end

    def trim_lines
        self.split("\n").collect do |line|
            match = line.match( /[\s]*([^\s]*.*)/mix )
            match[1]
        end
    end

    def trim_tabs
        trim_lines.join( ' ' )
    end

    private

    def String.string_camelize(lower_case_and_underscored_word, first_letter_in_uppercase = true)
      if first_letter_in_uppercase
        lower_case_and_underscored_word.to_s.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
      else
        "#{lower_case_and_underscored_word.first.downcase}#{String.string_camelize(lower_case_and_underscored_word)[1..-1]}"
      end
    end

end
