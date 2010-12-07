#!/usr/bin/env ruby

require 'rubygems'
require 'date'
require 'spec'
require 'postgres'

require File.dirname(__FILE__) + '/../../../spec_helper'

include BehaviourSupport
include MIS::Framework

#####################################################################################
##############                 Behaviour Support                     ################
#####################################################################################

#module ResultSetTestBehaviourSupport
#    
#    Varchar = 1043
#    SqlDate = 1082
#    Int8 = 20
#    Float8 = 701
#    Bool = 16
#
#    FieldInfo = Struct.new( "FieldInfo", :name, :type_oid )
#    
#    def create_empty_result_set
#        create_result_set nil
#    end
#    def instantitate_resultset pgresult
#        ResultSet.new pgresult
#    end
#    def method_missing( method_name, *args )
#        return super if [ :be_empty, :be_an_instance_of, :be_true, :raise_error ].include? method_name
#        implied_field_name = method_name.to_s
#        field = FieldInfo.new
#        field.name = implied_field_name
#        field.type_oid = args.first unless args.empty?
#        field
#    end
#    def get_example_pgresultset
#        name_field = name Varchar
#        date_field = dob SqlDate
#        PostgresPR::Connection::Result.new( get_example_rows, [ name_field, date_field ] )
#    end
#    def get_example_rows
#        (1..9).collect { |index| [ "Person number #{index}", Date.parse( "2007-05-0#{index}" ) ] }
#    end
#end

#####################################################################################
##############                 Behaviour Examples                    ################
#####################################################################################

describe given( DbNull ), 'when used in an implicitly null returning operation' do

    it "should not be the same as ruby's nil" do
        DbNull.nil?.should be_false
        obj = nil
        DbNull.should_not eql( obj )
        obj.db_nil?.should be_false
    end

end

describe given( ETL::Integration::SQL::ResultSet ), 'when initialized with data from an underlying sql query' do

    begin
        include ResultSetTestBehaviourSupport
    rescue LoadError, NameError
        require File.dirname(__FILE__) + "/spec_helper"
        retry
    end
    
    it 'should create a one to one mapping for each of the fields in the original object' do
        fields = (1..4).collect do |number|
            field = FieldInfo.new
            field.name = "column#{number}"
            field.type_oid = Varchar
            field
        end
        rows = [ fields.collect { |field| "value for #{field.name}" } ]
        subject = instantitate_resultset PostgresPR::Connection::Result.new( rows, fields )
        subject.should have( 4 ).columns
        subject.columns.should eql( fields )
    end

    it 'should be empty if the underlying result set is nil' do
        ResultSet.new( nil ).should be_empty
    end

    it 'should be empty if the underlying result set has no columns' do
        ResultSet.new( PostgresPR::Connection::Result.new( [], [] ) ).should be_empty
    end

    it 'should contain the same number of rows as the underlying result set' do
        resultset = instantitate_resultset get_example_pgresultset
        resultset.size.should eql( get_example_rows.size )
    end

    it 'should generate a class for its rows, with an attribute reader for each named column in the query' do
        pgresult = get_example_pgresultset
        resultset = instantitate_resultset pgresult
        sample_row = resultset[ 0 ]
        pgresult.fields.each do |field|
            sample_row.should respond_to( field.name )
        end
    end

    it 'should initialize each instance of the dynamically generated row class with the correct fields' do
        name_field = name Varchar
        age_field = age Int8
        my_name = 'Tim'
        my_age = 29
        rows = [ [ my_name, my_age ] ]
        fields = [ name_field, age_field ]
        pgresult = PostgresPR::Connection::Result.new( rows, fields )
        resultset = ResultSet.new( pgresult )
        row = resultset.rows.first
        row.name.should eql( my_name )
        row.age.should eql( 29 )
    end

    it 'should correctly map the data type(s) of each field in the query' do
        description_field = description Varchar
        product_line_id_field = product_line_id Int8
        discount_end_date_field = discount_end_date SqlDate
        price_field = price Float8
        active_field = active Bool
        desc, lineid, discount_end, unit_price, is_active = "Test product", 3, '2007-05-10', 23.99, true
        rows = [ [ desc, lineid, discount_end, unit_price, is_active ] ]
        fields = [ description_field, product_line_id_field, discount_end_date_field, price_field, active_field ]
        pgresult = PostgresPR::Connection::Result.new( rows, fields )
        resultset = instantitate_resultset pgresult
        sample_row = resultset.rows.first
        sample_row.description.should be_an_instance_of( String )
        sample_row.product_line_id.should be_an_instance_of( Fixnum )
        sample_row.discount_end_date.should be_an_instance_of( Date )
        sample_row.price.should be_an_instance_of( Float )
        sample_row.active.should be_an_instance_of( TrueClass )
    end

    it 'should map nil entries to instances of the DbNull class' do
        sole_field = count Int8
        empty_row = [ nil ]
        pgresult = PostgresPR::Connection::Result.new( [ empty_row ], [ sole_field ] )
        resultset = instantitate_resultset pgresult
        resultset.rows.first.count.db_nil?.should be_true
    end

    it 'should explode if an invalid data type conversion is initiated' do
        messed_up_field_info = incept_date SqlDate
        bad_row = [ 'foo the 29th of octoberish' ]
        pgresult = PostgresPR::Connection::Result.new( [ bad_row ], [ messed_up_field_info ] )
        lambda { resultset = instantitate_resultset pgresult }.should raise_error
    end

    it 'should return true when comparing to itself' do
        name_field = name Varchar
        age_field = age Int8
        my_name = 'Tim'
        my_age = 29
        rows = [ [ my_name, my_age ] ]
        fields = [ name_field, age_field ]
        pgresult = PostgresPR::Connection::Result.new( rows, fields )
        resultset = ResultSet.new( pgresult )
        row = resultset.rows.first
        row.eql?(row).should eql(true)
    end

    it 'should return false when comparing to nil' do
        name_field = name Varchar
        age_field = age Int8
        my_name = 'Tim'
        my_age = 29
        rows = [ [ my_name, my_age ] ]
        fields = [ name_field, age_field ]
        pgresult = PostgresPR::Connection::Result.new( rows, fields )
        resultset = ResultSet.new( pgresult )
        row = resultset.rows.first
        row.eql?(nil).should equal(false)
    end

    it 'should return false when comparing non-same row' do
        name_field = name Varchar
        age_field = age Int8
        my_name = 'Tim'
        my_age = 29
        rows = [ [ my_name, my_age ] ]
        fields = [ name_field, age_field ]
        pgresult = PostgresPR::Connection::Result.new( rows, fields )
        resultset = ResultSet.new( pgresult )
        row = resultset.rows.first

        name_field = name Varchar
        age_field = age Int8
        my_name = 'Tim'
        my_age = 15
        rows = [ [ my_name, my_age ] ]
        fields = [ name_field, age_field ]
        pgresult = PostgresPR::Connection::Result.new( rows, fields )
        resultset2 = ResultSet.new( pgresult )
        row2 = resultset2.rows.first

        row.eql?(row2).should equal(false)
    end
end
