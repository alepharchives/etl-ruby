#!/usr/bin/env ruby

require 'rubygems'

module ETL
    module Integration
        module Engine
            module Processors

                # Performs rules based multiplexed routing
                class Router

                    include Validation
                    include ETL::Integration::Engine::RuntimeSupportMixin
                    
                    def initialize()
                        super()
                    end

                    #TODO: set fault when redirect fails and remove invalid_message_channel from implementation

                    # Adds a new where (redirect) to this instance.
                    # Any processed data exchange will be forwarded to the supplied
                    # output channel if the rule evaluates true for that exchange.
                    def add_route( rule, output_channel )
                        validate_arguments( binding() )
                        routes.push( RouteSpecification.new( rule, output_channel ) )
                    end

                    # Processes the supplied data exchange.
                    def process( data_exchange )
                        validate_instance_variables( binding(), :routes )
                        _info("Routing exchange from #{origin(data_exchange)}.")
                        unless routes.redirect? data_exchange
                            _info("Routing failed for exchange #{origin(data_exchange)}.")
                            set_fault( data_exchange )
                        end
                    end

                    protected

                    class RouteSpecification
                        
                        include ETL::Integration::Engine::RuntimeSupportMixin
                        
                        initialize_with :rule, :output_channel, :validate => true

                        def redirect?( data_exchange )
                            if @rule.evaluate( data_exchange )
                                _debug("Successfully matched routing rule #{@rule} against exchange from [#{origin(data_exchange)}].")
                                @output_channel.marshal( data_exchange )
                                return true
                            end
                            return false
                        end
                        
                    end

                    def routes
                        if @routes.nil?
                            @routes = []
                            def @routes.redirect?( data_exchange )
                                self.each { |route|
                                    return true if route.redirect?( data_exchange )
                                }
                                return false
                            end
                        end
                        @routes
                    end

                    def set_fault( exchange )
                        fault_message = Message.new
                        fault_message.set_header(:fault_code, FaultCodes::RoutingError)
                        fault_message.set_header(:fault_description, 'Unable to redirect inbound message.')
                        exchange.fault = fault_message
                    end

                end
            end
        end
    end
end
