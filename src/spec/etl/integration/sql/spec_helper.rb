#!/usr/bin/env ruby

require 'rubygems'
require 'spec'

#require File.dirname(__FILE__) + '/../../../spec_helper'

#TODO: these should be in the bevaiour support module! 
Varchar = 1043
SqlDate = 1082
Int8 = 20
Float8 = 701
Bool = 16

FieldInfo = Struct.new( "FieldInfo", :name, :type_oid )

module ResultSetTestBehaviourSupport

    def create_empty_result_set
        create_result_set nil
    end
    
    def instantitate_resultset pgresult
        ResultSet.new pgresult
    end
    
    def method_missing( method_name, *args )
        return super if [ :be_empty, :be_an_instance_of, :be_true, :raise_error ].include? method_name
        implied_field_name = method_name.to_s
        field = FieldInfo.new
        field.name = implied_field_name
        field.type_oid = args.first unless args.empty?
        field
    end
    
    def get_example_pgresultset
        name_field = name Varchar
        date_field = dob SqlDate
        PostgresPR::Connection::Result.new( get_example_rows, [ name_field, date_field ] )
    end
    
    def get_example_rows
        (1..9).collect { |index| [ "Person number #{index}", Date.parse( "2007-05-0#{index}" ) ] }
    end
    
end
