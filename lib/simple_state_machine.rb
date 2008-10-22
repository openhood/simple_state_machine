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

      # define a method {state_column}_{state}? for each state
      states.each do |state|
        self.class_eval <<-eos
          def #{column.to_s}_#{state.to_s}?
            self[:#{column.to_s}] === '#{state.to_s}'
          end
        eos
      end

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
      end
    end
  end
end