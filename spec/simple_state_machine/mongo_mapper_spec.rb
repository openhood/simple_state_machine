require "spec_helper"

describe SimpleStateMachine::MongoMapper do
  before do
    @doc = Doc("Order") do
      plugin SimpleStateMachine::MongoMapper
    end
  end

  describe ".state_machine" do
    it "should be defined" do
      @doc.should respond_to(:state_machine)
    end
    it "should take 2 arguments" do
      lambda do
        @doc.state_machine
      end.should raise_error(ArgumentError)
      lambda do
        @doc.state_machine :state, [:initial]
      end.should_not raise_error(ArgumentError)
      lambda do
        @doc.state_machine 1, 1, 1
      end.should raise_error(ArgumentError)
    end
  end

  describe "when defining a state machine with :state, [:initial, :final]" do
    before do
      @doc.class_eval do
        state_machine :state, [:initial, :final]
      end
    end
    subject { @doc.new }
    it "should allow accessing states via states[:state]" do
      subject.states[:state].should == [:initial, :final]
    end
    it "should add a :state key of type String on model" do
      subject.key_names.should include("state")
      subject.keys["state"].type.should == String
    end
    it "should set state on object initialization with first state" do
      subject.state.should == :initial
    end
    it do
      subject.should be_state_initial
    end
    it do
      subject.should_not be_state_final
    end
    it "should allow reverting to previous state" do
      subject.state = :final
      subject.should be_state_final
      subject.state_revert
      subject.should be_state_initial
    end
    it "should allow setting state via a String" do
      subject.state = "final"
      subject.should be_state_final
    end
    it "should allow setting state via a Symbol" do
      subject.state = :final
      subject.should be_state_final
    end
    it "should return a symbol for state" do
      subject.state = "final"
      subject.state.should == :final
      subject.state = :final
      subject.state.should == :final
    end
    it "should validate state is included in allowed state" do
      subject.state = :unknown_state
      subject.valid?
      subject.errors[:state].should == ["is not included in the list"]
      subject.state = :final
      subject.valid?
      subject.errors[:state].should == []
    end
    
    describe "when defining a second state machine with :delivery_state, [:initial, :final]" do
      before do
        @doc.class_eval do
          state_machine :delivery_state, [:initial, :final]
        end
      end
      subject { @doc.new }
      it "should allow accessing states via states[:delivery_state]" do
        subject.states[:delivery_state].should == [:initial, :final]
      end
      it "should add a :delivery_state key of type String on model" do
        subject.key_names.should include("delivery_state")
        subject.keys["delivery_state"].type.should == String
      end
      it "should set delivery_state on object initialization with first delivery_state" do
        subject.delivery_state.should == :initial
      end
      it do
        subject.should be_delivery_state_initial
      end
      it do
        subject.should_not be_delivery_state_final
      end
      it "should allow reverting to previous state" do
        subject.delivery_state = :final
        subject.should be_delivery_state_final
        subject.delivery_state_revert
        subject.should be_delivery_state_initial
      end
      it "should not revert other state machine on reverting to previous state" do
        subject.state = :final
        subject.delivery_state = :final
        subject.should be_state_final
        subject.should be_delivery_state_final
        subject.delivery_state_revert
        subject.should be_state_final
        subject.should be_delivery_state_initial
      end
    end
  end
end