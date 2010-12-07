#!/usr/bin/env ruby

require 'rubygems'
require 'uri'
require 'etl/util'

module ETL
    module Integration
        module SQL
            # I am raised when something goes wrong during data access!
            class DataAccessException < BaseException
                attr_reader :message, :inner_exception, :severity, :error_code
                def initialize( message=$!, inner_exception=$ERROR_INFO, severity=:UNKNOWN, error_code=:UNKNOWN )
                    super(message, inner_exception)
                    local_variables.each { |var| instance_variable_set( "@#{var}", eval( var ) ) }
                end

                alias cause inner_exception
                
                def to_s
                    return "Severity: #{self.severity}, Error Code: #{self.error_code}"
                end
                
                def eql?( other )
                    instance_variables.each do |var|
                        return false unless other.send( :instance_variable_get, var ).eql?( self.instance_variable_get( var ) )
                    end
                    return true
                end
                
                def body()
                    return self.to_s
                end
            end

            # I am raised when a specialized data access problem occurs, owing
            # to connectivity problems with the underlying driver.
            class ConnectivityException < DataAccessException
                attr_reader :data_source_uri
                def initialize( data_source_uri="unknown", message="connectivity error occurred on #{data_source_uri}", 
                        inner_exception=$ERROR_INFO, severity=:UNKNOWN, error_code=:UNKNOWN )
                    super( message, inner_exception, severity, error_code )
                    @data_source_uri = data_source_uri
                end
            end
        end
    end
end
