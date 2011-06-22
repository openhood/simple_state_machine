module SimpleStateMachine
  module MongoMapper
    extend ActiveSupport::Concern

    included do
      class_eval do
        write_inheritable_attribute :states, {}
        class_inheritable_reader :states
      end
    end

    module ClassMethods
      def state_machine(column, column_states)
        inheritable_attributes[:states][column.to_sym] = column_states

        key column, String
        validates_inclusion_of column, :in => column_states

        define_method :"#{column}_revert" do
          write_key column, new? ? states[column].first : send(:"#{column}_was")
        end

        # define a method {state_column}_{state}? for each state
        column_states.each do |state|
          define_method :"#{column}_#{state}?" do
            send(column) === state
          end
        end
      end
    end

    module InstanceMethods
      def initialize(*args)
        super(*args)
        set_initial_state
      end

    private
      def write_key(key, value)
        super(key, states.keys.include?(key) ? value.to_s : value)
      end

      def read_key(key)
        value = super(key)
        value && states.keys.include?(key) ? value.to_sym : value
      end

      def set_initial_state
        states.each do |column, states|
          write_key column, states.first
        end if new?
      end
    end
  end
end