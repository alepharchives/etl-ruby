#!/usr/bin/env ruby

require 'rubygems'

module ETL
    module Integration
        module Engine

            #
            # Represents a pipeline of processing tasks/steps. A pipeline is
            # initialized with a set of processors, which can be applied to a
            # producer/consumer pair by calling the #Pipeline#execute method.
            #
            # Pipelines can process an #Exchange in exactly the same way as thier
            # parent class (#Service) and will also respond to #marshal, however,
            # the result of this processing is not passed on to any 'consumer', nor is
            # there any interaction with the underlying <i>producer</i> from which the
            # #Exchange came.
            class Pipeline < Service

                # Processes the input data exchanges unmarshalled from the 'producer' endpoint,
                # passing them through the collection of filters and marshalling the
                # final result(s) to the 'consumer' endpoint.
                def execute(producer, consumer)
                    validate_processing_args(producer, consumer)
                    _debug("Executing pipeline from [#{producer.uri()}] to [#{consumer.uri()}].")
                    last = nil
                    until(exchange = producer.unmarshal()).nil?
                        last_exchange = exchange.flip()
                        marshal(last_exchange)
                        process_consumer(last_exchange=last_exchange.flip(), consumer)
                    end
                    return last_exchange
                end

                protected
                def process_consumer(last_exchange, consumer)
                    _debug("Marshalling from origin [#{origin(last_exchange)}] to consumer [#{consumer.uri()}].")
                    consumer.marshal(last_exchange)
                    fault_channel.marshal(last_exchange) if last_exchange.has_fault?
                end

                private
                def validate_processing_args(producer, consumer)
                    validate_arguments(binding())
                end

            end

        end
    end
end
