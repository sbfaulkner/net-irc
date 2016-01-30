# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'net/irc/version'

Gem::Specification.new do |spec|
  spec.name          = 'net-irc'
  spec.version       = Net::IRC::VERSION
  spec.authors       = ['S. Brent Faulkner']
  spec.email         = ['sbfaulkner@gmail.com']

  spec.summary       = 'A ruby implementation of the IRC client protocol.'
  spec.description   = 'A ruby implementation of the IRC client protocol.'
  spec.homepage      = 'https://github.com/sbfaulkner/net-irc'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # TODO: needed? this is only required by nicl
  spec.add_development_dependency 'ruby-termios'

  spec.add_development_dependency 'byebug'

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec'
end
