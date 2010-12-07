#!/usr/bin/env ruby

require 'rubygems'
require 'spreadsheet/excel'

#class Worksheet
#    def write_internal_url(row, col, url, string=url, format=nil)
#        record = 0x01B8
#        length = 0x0034 + 2 * (1+url.length)
#        
#        url = url.remove_all(/^internal:/)
#
#        write_string(row,col,string,format)
#        
#        header = [record, length].pack("vv")
#        data   = [row, row, col, col].pack("vvvv")
#        
#        unknown = "D0C9EA79F9BACE118C8200AA004BA90B02000000"
#        
#        stream = [unknown].pack("H*")
#        
#        url = url.split('').join("\0")
#        url += "\0\0\0"
#        
#        len = url.length
#        url_len = [len].pack("V")
#        
#        append(header + data)
#        append(stream)
#        append(url_len)
#        append(url)
#    end
#end

module ETL
    module Transformation

        class ObjectToExcelTransformer
            FIRST_COLUMN = 0
            FIRST_ROW = 0
            STARTING_COLUMN_ROW = 4
            STARTING_DATA_ROW = 6
            
            include Validation
            
            def initialize( workbook )
                validate_arguments(binding())
                @workbook = workbook
            end
            
            public
            
            #            def add_summary(filename, queries)
            #                worksheet = add_worksheet('Summary')
            #                row_index = 0
            #                queries.each do |header, query|
            #                    make_hash_callable(query)
            #                    #                    worksheet.write(row_index, 0, link) 
            #                    #                    worksheet.write_url(row_index, 0, "#report1!A1", "click")
            #                    worksheet.write_internal_url(row_index, 0, "internal:'report1!A1'", "click")
            #                    #                    worksheet.write(row_index, 0, "=HYPERLINK(\"#report1!A1\",\"Sheet One\")", "click")
            #                    #                    write(row_index, 0, header)
            #                    #                    worksheet.write(row_index, 1, query.title)
            #                    row_index += 1
            #                end
            #            end
            
            def transform(dataset, options={})
                options = options[:mapping]
                validate_options(options)
                make_hash_callable(options)
                
                @formats = add_formats()
                worksheet = add_worksheet(options.worksheet)
                add_headers(options.meta_data, options.query, worksheet)
                add_data(dataset, worksheet, options.meta_data)
            end
            
            private
            
            def add_formats()
                # add formatting to worksheet
                formats  = {}
                formats[:title] = @workbook.add_format(:color => "blue", :bold=>1)
                formats[:no_format] = @workbook.add_format(:color => "black")
                formats[:column_header] = @workbook.add_format(:bold=> 1, :underline => 1)
                formats[:column_format] = @workbook.add_format(:font_shadow => true)
                formats[:number_column] = @workbook.add_format(:num_format => 0x0f)
                formats
            end
            
            def add_worksheet(worksheet)
                @workbook.add_worksheet(worksheet)
            end
            
            # add headers to the worksheet
            def add_headers(columns, header, worksheet)
                
                # print a numeric format
                f5 = Format.new(:num_format => 0x0f)
                worksheet.format_row(0..2, 15, @formats[:title] )
                # add headers
                worksheet.write(FIRST_ROW, FIRST_COLUMN, "Title: #{header.title.camelize}")
                worksheet.write(FIRST_ROW + 1, 0, "Description: #{header.description.camelize}")
                worksheet.write(FIRST_ROW + 2, 0, "Query: #{header.sql}")
                
                columns.each_with_index do |col, cindex|
                    worksheet.format_column(cindex, 15, @formats[:number_column]) # set width of column (15 fixed)
                    worksheet.write(STARTING_COLUMN_ROW, cindex, col.camelize, @formats[:column_header])
                end
            end
            
            # adds data for each column
            def add_data(dataset, worksheet, columns)
                dataset.rows.each_with_index do |row, rindex|
                    columns.each_with_index do |col, cindex|
                        # set column formatting
                        f = nil
                        cell_value = nil
                        col_length = row[col].to_s.length < 20 ? 20 : row[col].to_s.length
                        if row[col].kind_of? Fixnum or row[col].kind_of? Float
                            f = @formats[:number_column]
                            cell_value = [row[col]]
                        else
                            f = @formats[:column_format] 
                            cell_value = row[col].to_s
                        end
                        
                        worksheet.write(rindex + STARTING_DATA_ROW, cindex, cell_value, @formats[:column_format])
                        worksheet.format_column(cindex, col_length, f)
                    end
                end
            end
            
            def validate_options(options)
                raise ArgumentError, "worksheet not present in options" unless options.has_key? :worksheet
                raise ArgumentError, "meta_data not present in options" unless options.has_key? :meta_data
            end

        end

    end
end
