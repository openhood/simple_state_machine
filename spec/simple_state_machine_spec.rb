require File.dirname(__FILE__) + '/spec_helper'

class Chicken < ActiveRecord::Base
  state_machine :user_state, [:pending, :active, :removed, :on_hold]
  state_machine :validation_state, [:waiting, :reviewed, :validated, :invalid]
  def user_activate!
    return false if !user_state_pending?
    self.user_state = :active
    save! rescue user_state_revert
    user_state_active?
  end       
end

describe Chicken do

  it "should set initial user_state" do
    c = Chicken.new
    c.user_state.should === :pending
  end

  it "should set initial validation_state" do
    c = Chicken.new
    c.validation_state.should === :waiting
  end

  it "should store state value as string" do
    c = Chicken.new
    c[:user_state].should === 'pending'
  end

  it "should also accept strings as state values" do
    c = Chicken.new
    c.user_state = 'active'
    c.user_state.should === :active
  end

  it "should validate user_state stay inside possible states" do
    c = Chicken.new
    c.valid?.should === true
    c.user_state = 'waiting'
    c.valid?.should === false
  end

  it "should show all possible states in .states method" do
    Chicken.states.should === {
      :user_state => [:pending, :active, :removed, :on_hold],
      :validation_state => [:waiting, :reviewed, :validated, :invalid]
    }
  end

  it "should return be able to return to previous state" do
    c = Chicken.new
    c.user_state.should === :pending
    c.user_state = 'active'
    c.user_state.should === :active
    c.user_state_revert
    c.user_state.should === :pending
  end

  describe "custom event user_activate!" do

    it "should return true if on pending state" do
      c = Chicken.new
      c.user_activate!.should === true
    end

    it "should effectively change user_state" do
      c = Chicken.new
      c.user_activate!
      c.user_state.should === :active
    end

    it "should not affect validation_state" do
      c = Chicken.new
      c.user_activate!
      c.validation_state.should === :waiting
    end

    it "should return false if user_state is not pending" do
      c = Chicken.new
      c.user_state = :on_hold
      c.user_activate!.should === false
    end

  end

  describe "magic methods to test current state" do

    it "should handle the user_state_pending? method" do
      c = Chicken.new
      lambda {c.user_state_pending?}.should_not raise_error NoMethodError
    end

    it "should evaluate user_state_pending? to true initially" do
      c = Chicken.new
      c.user_state_pending?.should === true
    end

    it "should evaluate user_state_pending? to false after activation" do
      c = Chicken.new
      c.user_activate!
      c.user_state_pending?.should === false
    end

    it "should evaluate user_state_active? to false initially" do
      c = Chicken.new
      c.user_state_active?.should === false
    end

    it "should evaluate user_state_active? to true after activation" do
      c = Chicken.new
      c.user_activate!
      c.user_state_active?.should === true
    end

    it "should not catch user_state_invalid?" do
      c = Chicken.new
      lambda {c.user_state_invalid?}.should raise_error NoMethodError
    end

    it "should handle validation_state_waiting?" do
      c = Chicken.new
      lambda {c.validation_state_waiting?}.should_not raise_error NoMethodError
    end

    it "should evaluate validation_state_waiting? to true initially" do
      c = Chicken.new
      c.validation_state_waiting?.should === true
    end

  end

end