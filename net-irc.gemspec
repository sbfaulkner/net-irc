SPEC = Gem::Specification.new do |s| 
  # identify the gem
  s.name = "net-irc" 
  s.version = "0.9.3" 
  s.author = "S. Brent Faulkner" 
  s.email = "brentf@unwwwired.net" 
  s.homepage = "http://www.unwwwired.net" 
  # platform of choice
  s.platform = Gem::Platform::RUBY 
  # description of gem
  s.summary = "a ruby implementation of the IRC client protocol"
  s.files = %w(
                bin/nicl
                lib/net/irc.rb
                lib/net/hybrid.yml
                lib/net/hyperion.yml
                lib/net/ircu.yml
                lib/net/isupport.yml
                lib/net/rfc1459.yml
                lib/net/rfc2812.yml
                MIT-LICENSE
                net-irc.gemspec
                Rakefile
                README.markdown
              )
  s.require_path = "lib" 
  s.autorequire = "net/irc" 
  # s.test_file = "test/net-irc.rb" 
  s.has_rdoc = true 
  s.extra_rdoc_files = ["README.markdown"] 
  # s.add_dependency("fastercsv", ">= 1.2.3") 
  s.executables = ["nicl"]
end 
