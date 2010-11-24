Gem::Specification.new do |s|
  s.name     = 'simple_state_machine'
  s.version  = '1.0.0'
  s.date     = '2010-11-24'
  s.summary  = 'Same as acts_as_state_machine but on multiple columns and with more strict validation, allow creation of complex events with parameters, used successfully on critical financial applications for quite a long time'
  s.description = s.summary

  s.add_dependency 'activerecord', '>= 2.2.2'

  s.files = Dir['lib/**/*.rb']

  s.author   = 'Joseph Halter'
  s.email    = 'team@openhood.com'
  s.homepage = 'http://github.com/openhood/simple_state_machine'
end