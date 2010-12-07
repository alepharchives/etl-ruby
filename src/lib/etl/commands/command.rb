#!/usr/bin/env ruby

require 'rubygems'

module ETL

    module Commands

        class ProcessingError < StandardError

            #initialize_with :message => '$!', :inner_exception => nil, :attr_reader => true
            attr_reader :message, :inner_exception

            def initialize message=$!, inner_exception=nil
                @message = message
                @inner_exception = inner_exception
            end

        end

        class Command

            include Validation

            #initialize_with :source, :destination
            #validate_initializer_arguments :source, :destination

            protected

            def initialize( source, destination )
                raise ArgumentError if missing? source, destination
            end

            public

            #
            # Execute the command.
            #
            def execute( *args )
                delegate = method( :perform_execute )
                args = if delegate.arity != 0
                    self.send( :perform_execute, *args )
                else
                    self.send( :perform_execute )
                end
            rescue StandardError => err
                raise ProcessingError.new( "Execution failed with #{err.class}: #{err.message}", err )
            end

        end

    end

end
