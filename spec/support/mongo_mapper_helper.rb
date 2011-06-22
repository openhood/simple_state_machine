module SimpleStateMachine
  module RSpec
    module Helpers
      def Doc(name=nil, &block)
        klass = Class.new do
          include ::MongoMapper::Document
          set_collection_name "test#{rand(20)}"

          if name
            class_eval "def self.name; '#{name}' end"
            class_eval "def self.to_s; '#{name}' end"
          end
        end

        klass.class_eval(&block) if block_given?
        klass.collection.remove
        klass
      end

      def EDoc(name=nil, &block)
        klass = Class.new do
          include ::MongoMapper::EmbeddedDocument

          if name
            class_eval "def self.name; '#{name}' end"
            class_eval "def self.to_s; '#{name}' end"
          end
        end

        klass.class_eval(&block) if block_given?
        klass
      end

      ::RSpec::Matchers.define :have_timestamps do |name, states = []|
        description { "have keys created_at/updated_at of type Time" }
        match do |actual|
          keys = actual.keys.select{|key_name, key| ["created_at", "updated_at"].include?(key_name) && key.type==Time}
          keys.size == 2
        end
      end

      ::RSpec::Matchers.define :have_simple_state_machine do |name, states = []|
        description { "define a state machine \"#{name}\" with #{states.join(",")} states" }
        match do |actual|
          actual.states[name].eql?(states)
        end
      end

      ::RSpec::Matchers.define :have_scope do |name, options = {}|
        query = Plucky::Query.new(actual.class, options)
        description do
          s = "have a scope #{name} with"
          s << " #{query.criteria.source} criterias" if query.criteria.source.present?
          s << " and " if query.criteria.source.present? && query.options.source.present?
          s << " #{query.options.source.inspect} options" if query.options.source.present?
          s
        end
        match do |actual|
          actual.class.scopes[name] && 
          actual.class.scopes[name].call.criteria == query.criteria && 
          actual.class.scopes[name].call.options == query.options
        end
      end

      ::RSpec::Matchers.define :have_key do |name, klass, options = {}|
        description do
          s = "have key #{name} of class #{klass.name}"
          s << " with #{options[:default]} as default value" if options.has_key?(:default)
          s
        end
        match do |actual|
          key = actual.keys.detect{|key_name, key| key_name==name.to_s && key.type==klass}
          valid = !!key
          valid &&= key.last.default_value.eql?(options[:default]) if options.has_key?(:default)
          valid
        end
      end

      ::RSpec::Matchers.define :have_index do |*keys|
        description{ "have an index on #{keys.join(", ")}" }
        match do |actual|
          indexes = actual.collection.index_information.values.collect{|h| h["key"].keys}
          indexes.include? keys.collect(&:to_s)
        end
      end

      ::RSpec::Matchers.define :have_many do |name, options = {}|
        description do
          s = "have many "
          s << "embedded " if options[:embedded]
          s << "#{name}"
          s << " of class #{options[:class].name}" if options[:class]
          s << " ordered by '#{options[:order]}'" if options[:order]
          s
        end
        match do |actual, matcher|
          actual.associations.one? do |association_name, assocation|
            valid = association_name==name.to_s && assocation.type==:many
            valid &&= assocation.klass==options[:class] if options[:class]
            valid &&= !!options[:embedded]==actual.embedded_associations.include?(assocation)
            valid &&= !!options[:order]==assocation.query_options[:order] if options[:order]
            valid
          end
        end
      end

      ::RSpec::Matchers.define :have_one do |name, options = {}|
        description do
          s = "have one "
          s << "embedded " if options[:embedded]
          s << "#{name}"
          s << " of class #{options[:class].name}" if options[:class]
          s
        end
        match do |actual, matcher|
          actual.associations.one? do |association_name, assocation|
            valid = association_name==name.to_s && assocation.type==:one
            valid &&= assocation.klass==options[:class] if options[:class]
            valid &&= !!options[:embedded]==actual.embedded_associations.include?(assocation)
            valid
          end
        end
      end

      ::RSpec::Matchers.define :belong_to do |name, options = {}|
        description do
          s = "belong to #{name}"
          s << " of class #{options[:class].name}" if options[:class]
          s
        end
        match do |actual, matcher|
          actual.associations.one? do |association_name, assocation|
            valid = association_name==name.to_s && assocation.type==:belongs_to
            valid &&= assocation.klass==options[:class] if options[:class]
            valid
          end
        end
      end

      ::RSpec::Matchers.define :validate_presence_of do |field, options = {}|
        description do
          s = "validate presence of #{field}"
          s << " while still allowing nil" if options[:allow_nil]
          s << " for #{options[:groups]} validations" if options[:groups]
          s
        end
        match do |actual, matcher|
          validation_method = options[:groups] ? :"valid_for_#{options[:groups]}?" : :valid?
          actual.send "#{field}=", ""
          actual.send validation_method
          valid = !actual.errors[field].empty?
          if actual.keys[field] && actual.keys[field].default_value.nil?
            actual.send "#{field}=", nil
            actual.send validation_method
            valid && !!options[:allow_nil]==actual.errors[field].empty?
          end
          valid
        end
      end

      ::RSpec::Matchers.define :validate_length_of do |field, options = {}|
        min, max = options[:within].first, options[:within].last
        description do
          "validate length of #{field} within #{min}..#{max}"
        end
        match do |actual, matcher|
          actual.send "#{field}=", min.times.collect{"a"}.join
          actual.valid?
          valid = !actual.errors[field].include?("is invalid")
          actual.send "#{field}=", (min-1).times.collect{"a"}.join
          actual.valid?
          valid &&= actual.errors[field].include?("is invalid")
          actual.send "#{field}=", (max+1).times.collect{"a"}.join
          actual.valid?
          valid &&= actual.errors[field].include?("is invalid")
          valid
        end
      end

      ::RSpec::Matchers.define :validate_inclusion_of do |field, options = {}|
        min, max = options[:within].first, options[:within].last
        description do
          "validate inclusion of #{field} within #{min}..#{max}"
        end
        match do |actual, matcher|
          actual.send "#{field}=", min
          actual.valid?
          valid = !actual.errors[field].include?("is not in the list")
          actual.send "#{field}=", min.pred
          actual.valid?
          valid &&= actual.errors[field].include?("is not in the list")
          actual.send "#{field}=", max.succ
          actual.valid?
          valid && actual.errors[field].include?("is not in the list")
        end
      end

      ::RSpec::Matchers.define :validate_confirmation_of do |field|
        description { "validate confirmation of #{field}" }
        match do |actual, matcher|
          field_confirmation = "#{field}_confirmation"
          actual.send "#{field}=", "aaaa"
          actual.send "#{field_confirmation}=", "aaaa"
          actual.valid?
          valid = !actual.errors[field].include?("doesn't match confirmation")
          actual.send "#{field}=", "aaaa"
          actual.send "#{field}=", "bbbb"
          actual.valid?
          valid && actual.errors[field].include?("doesn't match confirmation")
        end
      end

      ::RSpec::Matchers.define :validate_uniqueness_of do |field, options = {}|
        description do 
          s = "validate uniqueness of #{field}"
          s << " case sensitive" if options[:case_sensitive]
          s << " case insensitive" unless options[:case_sensitive]
          s << " allowing blank value" if options[:allow_blank]
          s << " allowing nil value" if options[:allow_nil]
          s
        end
        match do |actual, matcher|
          existing = actual.class.first
          raise "you need to create at least one record before we can check for uniqueness" unless existing
          actual.attributes = existing.attributes.reject{|k,v| k == "_id" }
          actual.valid?
          valid = actual.errors[field].include?("has already been taken")
          actual.send "#{field}=", actual.send(field).swapcase
          actual.valid?
          if options[:case_sensitive]
            valid &&= !actual.errors[field].include?("has already been taken")
          else
            valid &&= actual.errors[field].include?("has already been taken")
          end
          if options[:allow_blank]
            actual.send "#{field}=", ""
            actual.valid?
            valid &&= !actual.errors[field].include?("has already been taken")
          end
          if options[:allow_nil]
            actual.send "#{field}=", nil
            actual.valid?
            valid &&= !actual.errors[field].include?("has already been taken")
          end
          valid
        end
      end

      ::RSpec::Matchers.define :validate_config_with do |key, klass|
        description{ "validate presence of #{key} of class #{klass} in config" }
        match do |actual, matcher|
          actual.config.delete key
          actual.valid?
          valid = actual.errors[:config].include? "#{key} is required"
          actual.config[key] = Class.new
          actual.valid?
          valid &&= actual.errors[:config].include? "#{key} should be #{klass}"
          value = mock
          value.stub(:kind_of?).with(klass).and_return true
          actual.config[key] = value
          actual.valid?
          valid &&= actual.errors[:config].none?{|error| error.starts_with?("#{key} ")}
          valid
        end
      end
    end
  end
end