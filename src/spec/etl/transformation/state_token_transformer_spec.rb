# #!/usr/bin/env ruby

require 'rubygems'
require 'spec'

require File.expand_path("#{File.dirname(__FILE__)}/../../")  + '/spec_helper'

include BehaviourSupport
include MIS::Framework

describe given( StateTokenTransformer::StateTokenTransformer::MappingRule ), 'when configuring a mapping rule' do

    before :each do
        @rule = StateTokenTransformer::MappingRule.new( :rule )
        @dummy_input = 'dummy input'
    end

    it 'should explode unless you supply a target state name' do
        lambda {
            @rule.extract_data( @dummy_input )
        }.should raise_error( InvalidOperationException, "no 'target state names' were supplied" )
    end

    it 'should explode unless a validating block is supplied' do
        @rule.target_state_names = [:state1]
        lambda do
            @rule.extract_data( @dummy_input )
        end.should raise_error( InvalidOperationException, "no 'validating block' was supplied" )
    end

    it 'should call the supplied validating block when applied to an input string' do
        supplied_argument = nil
        @rule.target_state_names = [:state1]
        @rule.validate_with { |input_string| supplied_argument = input_string }
        @rule.extract_data( @dummy_input )
        supplied_argument.should eql( @dummy_input )
    end

    it "should only apply it's validating block to a state with a matching name" do
        state1, state2 = nil, nil
        (1..2).each do |num|
            code=<<-CODE
                state#{num} = mock( 'state#{num}' )
                state#{num}.should_receive( :name ).at_least( 1 ).times.and_return( :state#{num} )
                state#{num}.should_receive( :token ).and_return( 'state#{num}' )
            CODE
            eval( code )
        end

        validating_block = lambda { |input| return input }

        rule1 = StateTokenTransformer::MappingRule.new( 'rule1' )
        rule2 = StateTokenTransformer::MappingRule.new( 'rule2' )
        rule1.target_state_names = [:state1]
        rule2.target_state_names = [:state2]
        [ rule1, rule2 ].each { |rule| rule.validate_with( &validating_block ) }

        rule1.apply_rule( [ state1, state2 ] ).should eql( 'state1' )
        rule2.apply_rule( [ state1, state2 ] ).should eql( 'state2' )
    end

end

describe given( StateTokenTransformer ), 'when configuring transformation mapping rules' do

    before :all do
        @dummy_validating_block = lambda {}
    end

    before :each do
        @xfrmr = StateTokenTransformer.new
    end


    it 'should always interact with the current mapping rule' do
        #prepare
        mapping = mock( 'mapping' )
        @xfrmr.send( :add_mapping_rule, mapping )

        #expectations
        mapping.should_receive( :target_state_names= ).once.with( [:lala] )
        mapping.should_receive( :validate_with ).once.with( &@dummy_validating_block )

        #act & assert
        @xfrmr.from_state(:lala).should eql( @xfrmr )
        @xfrmr.using( &@dummy_validating_block )
    end

    it 'should create mappings in the same order as the lines: \'get().from_state().using()\' were called' do
        #setup
        mapping1 = mock( 'mapping1' )
        mapping2 = mock( 'mapping2' )
        mapping3 = mock( 'mapping3' )

        mappings = [ mapping1, mapping2, mapping3 ]

        #expectations
        mapping1.should_receive( :target_state_names= ).once.with( [:state1] )
        mapping1.should_receive( :validate_with ).once.with( any_args )
        mapping2.should_receive( :target_state_names= ).once.with( [:state2] )
        mapping2.should_receive( :validate_with ).once.with( any_args )
        mapping3.should_receive( :target_state_names= ).once.with( [:state3] )
        mapping3.should_receive( :validate_with ).once.with( any_args )

        StateTokenTransformer::MappingRule.stub!( :new ).and_return { mappings.shift }

        #act
        @xfrmr.get(:digits).from_state(:state1).using(&@dummy_validating_block)
        @xfrmr.get(:letters).from_state(:state2).using(&@dummy_validating_block)
        @xfrmr.get(:app_id).from_state(:state3).using(&@dummy_validating_block)
    end

    it 'should pass the supplied input states on to the mapping rules' do
        #setup
        state1 = mock('state1')
        state2 = mock('state2')

        input_states = [ state1, state2 ]

        #expectations
        (1..3).each do |var_num|
            code=<<-CODE
                mapping#{var_num} = mock( 'mapping#{var_num}' )
                @xfrmr.send( :add_mapping_rule, mapping#{var_num} )
                mapping#{var_num}.should_receive( :apply_rule ).once.with( input_states )
            CODE
            eval( code )
        end

        #act
        @xfrmr.collect( input_states )
    end

    it "should construct mapping rules from a file content" do
        file_name = "test_file_name"
        rule1 = "get(:date).from_state(:date) { |input| input }"
        rule2 = "get(:time).from_state(:time) { |input| input }"
        rules = "[ '#{rule1}', '#{rule2}' ]"
        ::IO.should_receive( :read ).with( file_name ).and_return( rules )
        
        mock_rule1 = mock( 'rule1' )
        StateTokenTransformer::MappingRule.should_receive( :new ).with( :date ).and_return( mock_rule1 )
        mock_rule1.should_receive( :target_state_names= ).once.with( [:date] )
        mock_rule1.should_receive( :validate_with ).once.with( any_args )
        mock_rule2 = mock( 'rule2' )
        StateTokenTransformer::MappingRule.should_receive( :new ).with( :time ).and_return( mock_rule2 )
        mock_rule2.should_receive( :target_state_names= ).once.with( [:time] )
        mock_rule2.should_receive( :validate_with ).once.with( any_args )
                
        @xfrmr.load_mapping_rules( file_name )
    end
    
    it "be able use the environment attibute inside the transformation rules" do
        #setup
        env = 'test_env'
        file_name = "test_file_name"
        rule = "get(:env).from_state(:end) { |input| @environment }"
        rules = "[ '#{rule}' ]"
        ::IO.stub!( :read ).and_return( rules )        
        @xfrmr.load_mapping_rules( file_name )
        @xfrmr.environment = env

        state = mock('state')
        state.stub!(:name).and_return(:end)
        state.stub!(:token).and_return('2007-09-04 lala')

        #act
        result = @xfrmr.collect( [state] )

        #assert
        result.should eql( [ env ] )
    end
end

describe given( StateTokenTransformer ), 'when transforming parse results' do

    before :each do
        @xfrmr = StateTokenTransformer.new
    end

    it '\'collect\' method should get a stack of states and return an array of data based on mapping rules' do
        #setup
        mapping1 = StateTokenTransformer::MappingRule.new( :date )
        mapping1.target_state_names = [:state1]
        mapping1.validate_with { |token| token[0,10] }
        @xfrmr.send( :add_mapping_rule, mapping1 )

        state1 = mock('state1')
        state1.should_receive(:name).and_return(:state1)
        state1.should_receive(:token).and_return('2007-09-04 lala')

        #act
        result = @xfrmr.collect( [state1] )

        #assert
        result.should eql( [ '2007-09-04' ] )
    end
    
    it "convert nils into a NULL string" do
        #setup
        mapping1 = StateTokenTransformer::MappingRule.new( :date )
        mapping1.target_state_names = [:state1]
        mapping1.validate_with { |token| nil }
        @xfrmr.send( :add_mapping_rule, mapping1 )

        state1 = mock('state1')
        state1.should_receive(:name).and_return(:state1)
        state1.should_receive(:token).and_return('2007-09-04 lala')

        #act
        result = @xfrmr.collect( [state1] )

        #assert
        result.should eql( [ 'NULL' ] )
    end


    #TODO: fail?

    it 'should explode if the supplied input data does not match the given rule(s)' do
        @xfrmr.get( :foo ).from_state( :foo_state ) { |token| token.upcase }
        states = [ 1, 2 ].collect { |num|
            state = mock( "mock-state#{num}" )
            state.should_receive( :name ).and_return( :bar_state )
            state
        }

        lambda {
            @xfrmr.collect( states ).should eql( [ "NULL" ] )
        }.should_not raise_error
    end

    it 'should search for a given set of state names until it finds a match' do
        state1 = mock( 's1', :null_object => true )
        state2 = mock( 's2', :null_object => true )
        state3 = mock( 's3', :null_object => true )
        state1.should_receive( :name ).any_number_of_times.and_return( :state1 )
        state2.should_receive( :name ).any_number_of_times.and_return( :state2 )
        state3.should_receive( :name ).any_number_of_times.and_return( :state3 )

        @xfrmr.get( :first ).from_state( :state1 ) {}
        @xfrmr.get( :second ).from_state( :state2 ) {}
        @xfrmr.get( :third ).from_state( :unknown, :state3 ) { |input|
            input.name.should eql( :state3 )
        }

        @xfrmr.collect( [ state1, state2, state3 ] )
    end
end
