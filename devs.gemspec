# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'devs/version'

Gem::Specification.new do |spec|
  spec.name          = 'devs'
  spec.version       = DEVS::VERSION.dup
  spec.authors       = ['Romain Franceschini']
  spec.email         = ['franceschini.romain@gmail.com']
  spec.description   = %q{DEVS}
  spec.summary       = %q{Discrete EVent system Specification}
  spec.homepage      = "https://github.com/devs-ruby/devs"
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency('bundler', '~> 1.7')
  spec.add_development_dependency('rake', '~> 10.4')
  spec.add_development_dependency('yard', '~> 0.8')
  spec.add_development_dependency('pry', '~> 0.10')
  spec.add_development_dependency('pry-byebug', '~> 0.2')
  spec.add_development_dependency('minitest', '~> 5.5')

  spec.required_ruby_version = '>= 1.9.2'
end
