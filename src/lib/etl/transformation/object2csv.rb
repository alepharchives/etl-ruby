#!/usr/bin/env ruby

require 'rubygems'
require 'csv'

module ETL
    module Transformation

        class ObjectToCsvFileTransform

            include Validation

            def initialize( filename, delimiter = nil )
                #todo: replace filename with @writer
                @filename = filename
                @delimiter = delimiter ||= '|'
            end

            public

            # performs the transform specified by the options contained in 'keyword_hash'.
            #
            # dataset := an object or set of objects to be written to the
            #            underlying csv file.
            #
            # options := a hash containing options for executing the transform.
            # For this class, the valid options are;
            #
            # :mapping => [ list of object attribute names in the
            #       order you wish to write them to a file ]
            def transform( dataset, options={} )
                mapping_rules = unpack_mapping_rules( dataset, options )
                processing_strategy = create_processing_strategy dataset, mapping_rules
                #todo: replace with processing_strategy.call( @writer )
                begin
                    apply_strategy processing_strategy
                rescue NoMethodError => nme
                    raise InvalidMappingException.new( mapping_rules, dataset )
                rescue
                    raise TransformError.new, $!, caller
                end
            end

            private

            def unpack_mapping_rules( dataset, options )
                raise ArgumentError, 'dataset argument is requried' unless dataset
                raise ArgumentError, 'no mapping options supplied!' unless options
                require_entries_for( options, :mapping ) { |option| raise ArgumentError, "option #{option} is required" }
                mapping_rules = options[ :mapping ]
                raise InvalidMappingException.new( mapping_rules, dataset ) unless mapping_rules.size > 0
                mapping_rules
            end

            def apply_strategy( strategy )
                #todo: remove this in favour of delegating to a driver adapter instead (remove the file dependency)

                #note: to implementors => the structure of CSV::Writer#generate sucks from the
                #       point of view of implementing a connected *writer* positioned over a file stream.
                #
                #      What would be much better is to use a method to hold a file stream and flush/cleanup
                #       if (and only if) @writer#commit is called.

                File.open( @filename, 'a' ) do |outfile|
                    CSV::Writer.generate( outfile, @delimiter ) { |csv| strategy.call( csv ) }
                end
            end

            def create_processing_strategy( dataset, mapping_rules )
                #todo: in all implementations, replace csv_file << ... with
                #
                #   @writer.write build_csv_entry( dataset, mapping_rules )
                #

                if isa_duck( dataset, mapping_rules )
                    processing_strategy = lambda do |csv_file|
                        #nb: method << is an alias for add_row (useful if setting up a driver adapter!?)
                        csv_file << build_csv_entry( dataset, mapping_rules )
                    end
                elsif dataset.respond_to? :each
                    processing_strategy = lambda do |csv_file|
                        dataset.each do |element|
                            csv_file << build_csv_entry( element, mapping_rules )
                        end
                    end
                else
                    raise InvalidMappingException.new( mapping_rules, dataset )
                end
            end

            def build_csv_entry( raw_data, mapping_rules )
                entry = mapping_rules.collect do |item|
                    raw_data.send item.to_sym
                end
            end

            def isa_duck( thing, behaviours )
                behaviours.each do |behaviour|
                    return false unless thing.respond_to? behaviour
                end
                true
            end
        end

    end
end
