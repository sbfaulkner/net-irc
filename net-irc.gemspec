SPEC = Gem::Specification.new do |s| 
  # identify the gem
  s.name = "net-irc" 
  s.version = "0.0.2" 
  s.author = "S. Brent Faulkner" 
  s.email = "brentf@unwwwired.net" 
  s.homepage = "http://www.unwwwired.net" 
  # platform of choice
  s.platform = Gem::Platform::RUBY 
  # description of gem
  s.summary = "a ruby implementation of the IRC client protocol"
  s.files = %w(examples/test.rb lib/net/irc.rb lib/net/rfc2812.yml MIT-LICENSE Rakefile README.markdown net-irc.gemspec)
  s.require_path = "lib" 
  s.autorequire = "irc" 
  # s.test_file = "test/net-irc.rb" 
  s.has_rdoc = true 
  s.extra_rdoc_files = ["README.markdown"] 
  # s.add_dependency("fastercsv", ">= 1.2.3") 
  # s.executables = ["rsql"]
end 
