#!/usr/bin/env ruby

module ETL
    module Transformation

        class StateTokenTransformer
          
            attr_accessor :environment

            mixin Validation
            
            class MappingRule

                attr_reader :name, :target_state_names

                def initialize( name )
                    @name = name
                    @target_state_names = nil
                    @validating_block = nil
                end

                def target_state_names=( *names )
                    @target_state_names = names.flatten
                end

                def validate_with( &block )
                    @validating_block = block
                end

                def apply_rule( states )
                    for state in states
                        return extract_data( state.token ) if @target_state_names.include? state.name
                    end
                    #raise InvalidMappingException.new( [ self ], nil )
                    return "NULL"
                end

                def extract_data( target )
                    guard_against_missing_state
                    @validating_block.call( target )
                end

                private

                def guard_against_missing_state
                    #todo: use the Validation module for this...
                    instance_variables.sort.each do |state|
                        if instance_variable_get(state).nil?
                            raise InvalidOperationException.new( "no '#{launder_state_name(state)}' #{pluralize(state)} supplied" )
                        end
                    end
                end

                def pluralize( state )
                    if state.ends_with? 's'
                        return 'were'
                    else
                        return 'was'
                    end
                end

                def launder_state_name( state )
                    state.gsub( /_/, ' ' ).gsub( /\@/, '' )
                end

            end

            def initialize
                @mappings = []
            end

            def get( output_name )
                mapping = MappingRule.new( output_name )
                @mappings.push mapping
                return self
            end

            def from_state( *state_names, &block )
                @mappings.last.target_state_names = state_names
                self.using( &block ) unless block.nil?
                return self
            end

            def using( &block )
                @mappings.last.validate_with( &block )
            end

            def collect( states )
                @mappings.collect { |rule| 
                    res = rule.apply_rule( states )
                    coalesce_empty( res, 'NULL' )
                }
            end
            
            def transform( states )
                self.collect( states )
            end
            
            def load_mapping_rules( file_uri )
                rules = eval ::IO.read( file_uri )
                rules.each do |rule|
                    eval rule
                end
            end

            private
            def add_mapping_rule( mapping_rule )
                @mappings.push mapping_rule
            end
        end
    end
end
