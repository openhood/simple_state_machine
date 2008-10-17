module SimpleStateMachine
  
  def self.included(base)
    base.extend Macro
  end
  
  module Macro
    def state_machine(column, states)
      create_empty_state_machine unless inheritable_attributes.key? :states
      inheritable_attributes[:states][column.to_sym] = states
      validates_format_of column, :with => Regexp.new('\A' + states.join('|') + '\Z')
      # should also override getter/setter to convert to strings
      self.class_eval <<-eos
        private :previous_state
        private :previous_state=
        def #{column.to_s}=(value)
          previous_state[:#{column.to_s}] = self[:#{column.to_s}]
          self[:#{column.to_s}] = value.to_s
        end
        def #{column.to_s}
          self[:#{column.to_s}].to_sym
        end
        def #{column.to_s}_revert
          self[:#{column.to_s}] = previous_state[:#{column.to_s}]
        end
      eos

    end

  private

    def create_empty_state_machine
      write_inheritable_attribute :states, {} # add a class variable
      class_inheritable_reader    :states     # make it read-only
      write_inheritable_attribute :previous_state, {}
      class_inheritable_accessor  :previous_state
      
      # set initial states on new objects
      if(!instance_methods.include? 'after_initialize')
        self.class_eval do
          def after_initialize # ActiveRecord::Base requires explicit definition of this function to use the callback
          end
        end
      end
      after_initialize :set_initial_states
      self.class_eval do
        def set_initial_states
          states.each {|column, states|
            self[column] = states.first.to_s
          } if(@new_record)
        end
        
        # define a method {state_column}_{state}? for each state
        def method_missing_with_state_checking(sym, *args, &block)
          if match = Regexp.new('\\A(' + self.states.keys.join('|') + ')_(.+)\\?\\Z').match(sym.to_s)
            column, value = match.captures
            return self[column.to_sym] === value.to_s if self.states[column.to_sym].include?(value.to_sym)
          end
          self.method_missing_without_state_checking(sym, *args, &block)
        end
        alias_method_chain :method_missing, :state_checking # allow overloading method_missing further
      end
    end
  end
end