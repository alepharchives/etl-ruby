#!/usr/bin/env ruby

require "rubygems"

module ETL
    module Integration
        module Engine
            module Channels

                #TODO: this should really log message to the database instead of just _info!

                # Implements a deal letter channel.
                class DeadLetterChannel

                    include ETL::Integration::Engine::RuntimeSupportMixin

                    # Marshals the exchange into this channel.
                    def marshal(exchange)
                        Kernel._info("Received exchange from [#{origin(exchange)}].", nil, self)
                    end

                end
            end
        end
    end
end
