#!/usr/bin/env ruby

require 'rubygems'
require 'postgres'

module ETL
    module Integration
        module SQL
            
            #
            # A read-only, in memory view of a sql result set.
            #
            class ResultSet

                include PostgreSqlAdapter::TypeOIDs

                # A tag representing the command used to generate the result set.
                attr_reader :command_tag
                
                # An immutable collection of row objects. Each row is a dynamically generated
                # object with typed read only properties representing each of the fields in the underlying
                # result set.
                attr_reader :rows

                def initialize( original_result_set )
                    @strict_type_mappings = false
                    if original_result_set.nil?
                        @command_tag, @columns = '', ImmutableCollection.empty
                    else
                        @command_tag, @columns =
                            original_result_set.cmd_tag, ImmutableCollection.new( original_result_set.fields )
                    end
                    if @columns.empty?
                        @rows = ImmutableCollection.empty
                    else
                        declared_columns = @columns.collect { |col| ':' + col.name }.join( ', ' )
                        @data_row_clazz = Class.new
                        @data_row_clazz.class_eval(<<-CODE
                            initialize_with #{ declared_columns }, :attr_reader => true
                            def []( name )
                                return self.send( name.to_sym )
                            end

                            def eql?(obj)
                                return false unless obj.instance_of?(self.class)
                                comparisons = [#{declared_columns}].collect do |sym|
                                    self.send(sym).eql?(obj.send(sym))
                                end
                                !comparisons.include?(false)
                            end
                        CODE
                        )
                        converted_rows = original_result_set.rows.collect do |raw_row|
                            initializer_arguments = []
                            field_index = 0
                            until field_index == @columns.size
                                initializer_arguments.push(
                                    map_data_type( @columns[ field_index ], raw_row.shift )
                                )
                                field_index += 1
                            end
                            @data_row_clazz.send( :new, *initializer_arguments )
                        end
                        @rows = ImmutableCollection.new converted_rows
                    end
                end

                # A collection of objects representing the data columns from the
                # underlying sql result set. Each column has a 'name' property, which can
                # be used to index access to the fields of objects stored in the #rows collection.
                #
                def columns
                    @columns
                end

                alias fields columns

                # Index based accessor for #rows
                def []( index )
                    @rows[ index ]
                end

                # An iterator for the #rows collection.
                def each
                    for row in @rows
                        yield row
                    end
                end

                alias each_row each

                # Query to determine the "filled-ness" of the result set. :P
                def empty?
                    @rows.empty?
                end

                # Query for the number of row objects in the #rows collection.
                def rowcount
                    @rows.size
                end

                alias size rowcount
                alias row_count rowcount

                private

                #TODO: replace this by just using *freeze* on an array!??!!
                class ImmutableCollection < Array

                    alias __add_items concat

                    undef_method    :concat,
                                    :<<,
                                    :push,
                                    :pop,
                                    :shift,
                                    :unshift,
                                    :clear,
                                    :[]=,
                                    :delete,
                                    :delete_at,
                                    :delete_if,
                                    :fill,
                                    :replace

                    instance_methods.find_all { |method|
                        method.ends_with? '!'
                    }.each { |state_mutating_method|
                        class_eval do
                            undef_method state_mutating_method.to_sym
                        end
                    }

                    def initialize( items=[] )
                        self.__add_items items
                    end

                    @@empty_collection = nil

                    def ImmutableCollection.empty
                        @@empty_collection = ImmutableCollection.new if @@empty_collection.nil?
                        @@empty_collection
                    end

                end
            end
        end
    end
end
