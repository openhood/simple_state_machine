require "active_record"
require "mongo_mapper"
require "simple_state_machine"
require "simple_state_machine/active_record"
require "simple_state_machine/mongo_mapper"

Dir[File.expand_path("../support/*.rb", __FILE__)].each{|f| require f}

log_dir = File.expand_path('../../log', __FILE__)
FileUtils.mkdir_p(log_dir) unless File.exist?(log_dir)
logger = Logger.new(log_dir + '/test.log')

ActiveRecord::Base.logger = logger
ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
load File.expand_path("../db/schema.rb", __FILE__)


MongoMapper.connection = Mongo::Connection.new('127.0.0.1', 27017, :logger => logger)
MongoMapper.database = "simple_state_machine_test"

RSpec.configure do |config|
  config.before(:each) do
    MongoMapper.database.collections.each { |c| c.drop_indexes }
  end
  config.include SimpleStateMachine::RSpec::Helpers
end