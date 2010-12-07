#!/usr/bin/env ruby

require 'parsedate'
include ParseDate

module ETL
    module Integration
        module SQL

            class DbNull
                def db_nil?
                    true
                end
                def to_s
                    'NULL'
                end
                def eql? other
                    other.kind_of? DbNull
                end
                def ==( other )
                    self.eql? other
                end
            end

            module PostgreSqlAdapter
                module TypeOIDs

                    class TypeConverter
                        def convert subject
                            return subject.to_str if subject.respond_to? :to_str
                            return subject
                        end
                    end

                    class DateConverter
                        def convert subject
                            return subject if subject.instance_of? Date
                            Date.new( *parsedate( subject, guessYear=false ).slice(0..2) )
                        end
                    end

                    class TimeConverter
                        def convert subject
                            return subject if subject.instance_of? Time
                            Time.parse subject
                        end
                    end

                    class StrictIntegerConverter
                        def convert subject
                            return Integer( subject )
                        end
                    end

                    class StrictFloatConverter
                        def convert subject
                            return Float( subject )
                        end
                    end

                    class BooleanConverter
                        def convert subject
                            return subject if [ TrueClass, FalseClass ].include? subject
                            return eval( subject.to_s ) if [ 'true', 'false' ].include? subject.to_s.downcase
                            case subject
                            when 't'
                                return true
                            when 'f'
                                return false
                            end
                            raise ArgumentError, "cannot convert #{subject.inspect} to a true/false value", caller
                        end
                    end

                    class NilConverter
                        def convert subject
                            raise ArgumentError, "#{subject.inspect} is not nil!" unless subject.nil?
                            return DbNull.new
                        end
                    end

                    @@nil_converter = NilConverter.new
                    @@default_converter = TypeConverter.new
                    @@boolean_converter = BooleanConverter.new
                    @@date_converter = DateConverter.new
                    @@time_converter = TimeConverter.new
                    @@strict_integer_converter = StrictIntegerConverter.new
                    @@strict_float_converter = StrictFloatConverter.new

                    @@type_oids = {
                        16 => :BOOL,
                        17 => :BYTEA,
                        18 => :CHAR,
                        19 => :NAME,
                        20 => :INT8,
                        21 => :INT2,
                        22 => :INT2VECTOR,
                        23 => :INT4,
                        24 => :REGPROC,
                        25 => :TEXT,
                        26 => :OID,
                        27 => :TID,
                        28 => :XID,
                        29 => :CID,
                        30 => :OIDVECTOR,
                        71 => :PG_TYPE_RELTYPE_,
                        75 => :PG_ATTRIBUTE_RELTYPE_,
                        81 => :PG_PROC_RELTYPE_,
                        83 => :PG_CLASS_RELTYPE_,
                        600 => :POINT,
                        601 => :LSEG,
                        602 => :PATH,
                        603 => :BOX,
                        604 => :POLYGON,
                        628 => :LINE,
                        700 => :FLOAT4,
                        701 => :FLOAT8,
                        702 => :ABSTIME,
                        703 => :RELTIME,
                        704 => :TINTERVAL,
                        705 => :UNKNOWN,
                        718 => :CIRCLE,
                        790 => :CASH,
                        829 => :MACADDR,
                        869 => :INET,
                        650 => :CIDR,
                        1007 => :INT4ARRAY,
                        1033 => :ACLITEM,
                        1042 => :BPCHAR,
                        1043 => :VARCHAR,
                        1082 => :DATE,
                        1083 => :TIME,
                        1114 => :TIMESTAMP,
                        1184 => :TIMESTAMPTZ,
                        1186 => :INTERVAL,
                        1266 => :TIMETZ,
                        1560 => :BIT,
                        1562 => :VARBIT,
                        1700 => :NUMERIC,
                        1790 => :REFCURSOR,
                        2202 => :REGPROCEDURE,
                        2203 => :REGOPER,
                        2204 => :REGOPERATOR,
                        2205 => :REGCLASS,
                        2206 => :REGTYPE,
                        2249 => :RECORD,
                        2275 => :CSTRING,
                        2276 => :ANY,
                        2277 => :ANYARRAY,
                        2278 => :VOID,
                        2279 => :TRIGGER,
                        2280 => :LANGUAGE_HANDLER,
                        2281 => :INTERNAL,
                        2282 => :OPAQUE,
                        2283 => :ANYELEMENT
                    }
		    
		    @@type_oids.invert.each do |type_name, oid_number|
			reader_property = type_name.to_s.camelize.to_sym
			define_method(reader_property) do
			    return oid_number
                        end
			alias_method type_name, reader_property
                    end

                    @@conversions = Hash.new( @@default_converter ).update(
                        :BOOL => @@boolean_converter,
                        :DATE => @@date_converter,
                        :TIME => @@time_converter,
                        :TIMESTAMP => @@time_converter,
                        :TIMESTAMPTZ => @@time_converter,
                        :BIT => @@strict_integer_converter,
                        :VARBIT => @@strict_integer_converter,
                        :INT8 => @@strict_integer_converter,
                        :INT2 => @@strict_integer_converter,
                        :INT4 => @@strict_integer_converter,
                        :NUMERIC => @@strict_float_converter,
                        :FLOAT4 => @@strict_float_converter,
                        :FLOAT8 => @@strict_float_converter
                    )

                    def map_data_type( field, value, use_strict=true )
                        raise ArgumentError if field.nil?
                        return @@nil_converter.convert( value ) if value.nil?
                        raise ArgumentError, 'unknown field descriptor type', caller unless field.respond_to? :type_oid
                        raise ArgumentError, 'unknown oid', caller unless @@type_oids.has_key? field.type_oid
                        type_name = @@type_oids[ field.type_oid ]
                        conversion = @@conversions[ type_name ]
                        return conversion.convert( value )
                    end

                end
            end
        end
    end
end
