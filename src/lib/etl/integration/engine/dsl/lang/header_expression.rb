#!/usr/bin/env ruby

require 'rubygems'

module ETL
    module Integration
        module Engine
            module DSL
                module Lang
                    # An expression that resolves the contents of a specific
                    # header at runtime and returns it.
                    class HeaderExpression < Expression

                        binary_operator(:&, :|, :+, :-, :/, :*, :>, :<)
                        
                        alias_method(:and, :&)
                        alias_method(:or, :|)
                        alias_method(:plus, :+)
                        alias_method(:add, :plus)
                        alias_method(:minus, :-)
                        alias_method(:multiplied_by, :*)
                        alias_method(:times, :*)
                        alias_method(:divided_by, :/)
                        alias_method(:divide, :divided_by)
                        alias_method(:greater_than, :>)
                        alias_method(:less_than, :<)

                        conversion_to(:equals, :matches, :if, :unless)

                        initialize_with :header_name, :validate => true, :attr_reader => true

                        # evaluates the supplied exchange, returning the
                        # header with the specified name, or raising an
                        # #ETL::Integration::Engine::DSL::InvalidExpressionException
                        # if the header cannot be read.
                        def evaluate(exchange)
                            response = do_eval(exchange)
                            _debug("Evaluating exchange [#{origin(exchange)}] against header name [#{@header_name}] and responding with [#{response}].")
                            return response
                        end

                        private

                        def do_eval(exchange)
                            return nil if exchange.nil?
                            if exchange.inbound.nil?
                                headers = exchange.outbound.headers
                            else
                                headers = exchange.inbound.headers
                            end
                            raise InvalidExpressionException.new(self) unless headers.has_key?(@header_name)
                            return headers[@header_name]
                        end

                    end
                end
            end
        end
    end
end
