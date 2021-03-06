require "active_record"

module SimpleStateMachine
  module ActiveRecord
    extend ActiveSupport::Concern
    
    included do |base|
      base.extend ClassMethods
    end

    module ClassMethods
      def state_machine(column, states)
        create_empty_state_machine unless respond_to? :states
        self.states[column.to_sym] = states
        validates_inclusion_of column, :in => states
        # should also override getter/setter to convert to strings
        self.class_eval <<-eos
          def #{column.to_s}=(value)
            self[:#{column.to_s}] = value.to_s
          end
          def #{column.to_s}
            self[:#{column.to_s}].to_sym
          end
          def #{column.to_s}_revert
            self[:#{column.to_s}] = self.new_record? ? states[:#{column.to_s}].first.to_s : self.#{column.to_s}_was
          end
        eos

        # define a method {state_column}_{state}? for each state
        states.each do |state|
          self.class_eval <<-eos
            def #{column.to_s}_#{state.to_s}?
              self[:#{column.to_s}] === "#{state.to_s}"
            end
          eos
        end

      end

    private

      def create_empty_state_machine
        class_attribute :states
        self.states = {}

        after_initialize :set_initial_states
        self.class_eval do
          def set_initial_states
            states.each {|column, states|
              self[column] = states.first.to_s
            } if new_record?
          end
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include SimpleStateMachine::ActiveRecord
end