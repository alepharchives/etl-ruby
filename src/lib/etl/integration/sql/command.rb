#!/usr/bin/env ruby

require 'rubygems'

module ETL
    module Integration
        module SQL
            class DatabaseCommand

                initialize_with :driver, :command_text, :validate => true

                def command_text
                    #TODO: fix this logic as it only applies to a thing returned from String#trim_lines
                    return @command_text unless @cmd_txt_buffer.nil?
                    @cmd_txt_buffer = StringIO.new( '' )
                    @cmd_txt_buffer.puts @command_text
                    @command_text = @cmd_txt_buffer.string.chomp
                end

                # Executes the command using the supplied parameters.
                def execute *params
                    sql = parse_args( *params )
                    @driver.execute( sql )
                end

                def prepare!

                    #todo: move all this into a state object (or consider a separate prepared_statement class)

                    sql = command_text.dup
                    argument_marker = 0
                    next_argument_marker = lambda do
                        argument_marker = argument_marker.succ
                        argument_marker
                    end
                    (0...sql.length).each do |character_index|
                        substring = sql[character_index..character_index]
                        sql[character_index..character_index] = "$#{next_argument_marker.call}" if [ '?', '%s' ].include? substring
                    end
                    prepare_plan_sql=<<-SQL
                        prepare #{plan_name} as
                        #{sql}
                    SQL
                    @driver.execute prepare_plan_sql.trim_lines.join( $/ )
                    method_call_expression = command_text.scan( /\?/mix ).join( ', ' )
                    method_call_expression = "( #{method_call_expression} )" if method_call_expression.size > 0
                    @command_text = "execute #{plan_name}#{method_call_expression};"
                    @driver.register_shutdown_callback do
                        self.deallocate!
                    end
                end

                def deallocate!
                    @driver.execute "deallocate #{plan_name};"
                end

                private

                def parse_args *params
                    command_text.gsub( /\?/mix, '%s' ) % params.collect do |param|
                        !param.nil? ? (( param.kind_of? String ) ? "\'#{param}\'" : param) : "NULLIF(1,1)"
                    end
                end

                def plan_name
                    "etl4r_plan_#{object_id.to_s.gsub(/-/, '')}"
                end

            end
        end
    end
end
