# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "simple_state_machine/version"

Gem::Specification.new do |s|
  s.name        = "openhood-simple_state_machine"
  s.version     = SimpleStateMachine::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Joseph HALTER", "Jonathan TRON"]
  s.email       = "team@openhood.com"
  s.homepage    = "http://github.com/openhood/simple_state_machine"
  s.summary     = %q{Same as acts_as_state_machine but on multiple columns and with more strict validation, allow creation of complex events with parameters, used successfully on critical financial applications for quite a long time}
  s.description = s.summary

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency("rake", ["~> 0.8.7"])
  s.add_development_dependency("rspec", ["~> 2.6.0"])
  s.add_development_dependency("sqlite3")
  s.add_development_dependency("activerecord", [">= 3.0.0"])
  s.add_development_dependency("mongo_mapper", ["~> 0.9.0"])
end