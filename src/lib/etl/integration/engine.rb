#!/usr/bin/env ruby

require 'rubygems'
require 'etl/integration/engine/fault_codes'
require 'etl/integration/engine/exception'
require 'etl/integration/engine/message'
require 'etl/integration/engine/exchange'
require "etl/integration/engine/runtime_support_mixin"
require 'etl/integration/engine/endpoint'
require 'etl/integration/engine/service'
require 'etl/integration/engine/pipeline'
require 'etl/integration/engine/execution_context'

require 'etl/integration/engine/processors/processor'
require 'etl/integration/engine/processors/router'
require 'etl/integration/engine/processors/multicast_router'
require 'etl/integration/engine/processors/endpoint_processor'
require 'etl/integration/engine/processors/pipeline_consumer'
require 'etl/integration/engine/processors/pipeline_processor'
require 'etl/integration/engine/processors/parser_processor'
require 'etl/integration/engine/processors/sql_command_processor'
require 'etl/integration/engine/processors/command_processor'
require 'etl/integration/engine/processors/transformer_processor'
require 'etl/integration/engine/processors/sql_bulk_loader_processor'

require 'etl/integration/engine/channels/default_error_channel'
require 'etl/integration/engine/channels/database_error_channel'
require 'etl/integration/engine/channels/database_audit_channel'
require 'etl/integration/engine/channels/dead_letter_channel'

require 'etl/integration/engine/endpoints/exception'
require 'etl/integration/engine/endpoints/directory_endpoint'
require 'etl/integration/engine/endpoints/file_endpoint'
require 'etl/integration/engine/endpoints/endpoint_filter'
require 'etl/integration/engine/endpoints/database_endpoint'
require 'etl/integration/engine/endpoints/processor_endpoint'
require 'etl/integration/engine/endpoints/email_endpoint'
require 'etl/integration/engine/endpoints/splitter'

require 'etl/integration/engine/dsl/exception'
require 'etl/integration/engine/dsl/lang/expression'
require 'etl/integration/engine/dsl/lang/binary_expression'
require 'etl/integration/engine/dsl/lang/equals_expression'
require 'etl/integration/engine/dsl/lang/matches_expression'
require 'etl/integration/engine/dsl/lang/if_expression'
require 'etl/integration/engine/dsl/lang/unless_expression'
require 'etl/integration/engine/dsl/lang/header_expression'
require 'etl/integration/engine/dsl/processor_support_mixin'
require 'etl/integration/engine/dsl/builder'
require 'etl/integration/engine/dsl/pipeline_builder'
require 'etl/integration/engine/dsl/service_builder'
require 'etl/integration/engine/dsl/expression_builder_mixin'
require 'etl/integration/engine/dsl/endpoint_filter_builder'
require 'etl/integration/engine/dsl/pipeline_consumer_builder'
require 'etl/integration/engine/dsl/route_builder'
require 'etl/integration/engine/dsl/builder_support_mixin'

require "etl/integration/engine/container/exception"
require "etl/integration/engine/container/service_execution_environment_support"
require 'etl/integration/engine/container/service_configuration_builder'
require 'etl/integration/engine/container/service_builder_visitor'
require 'etl/integration/engine/container/service_loader_mixin'
require 'etl/integration/engine/container/service_loader'
require 'etl/integration/engine/container/service_precompiler'
require 'etl/integration/engine/container/application'

module PackageSupport

    def invalid_exception_hierarchy_detected
	raise InvalidOperationException.new(
	    message=ETL::Integration::Engine::FaultCodes::InvalidLayerExceptionMessage), message, caller
    end

    def kind_of_exception?(const)
	const.kind_of?(Class) && const.ancestors.include?(Exception)
    end

    def invalid_subclassing?(const)
	return !(const.ancestors.include?(ETL::Integration::Engine::ExecutionException))
    end

end

module MIS
    module Engine

	extend PackageSupport
	include ETL::Integration::Engine
        include ETL::Integration::Engine::FaultCodes
        include ETL::Integration::Engine::Channels
        include ETL::Integration::Engine::Processors
        include ETL::Integration::Engine::Endpoints
	include ETL::Integration::Engine::DSL
	include ETL::Integration::Engine::DSL::Lang
	include ETL::Integration::Engine::Container

	invalid_exception_hierarchy_detected if constants.any? { |const_name|
	    member = const_get(const_name)
	    #puts const_name if kind_of_exception?(member)
	    kind_of_exception?(member) && invalid_subclassing?(member)
	}

    end
end
