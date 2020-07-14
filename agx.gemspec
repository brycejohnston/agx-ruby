# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'agx/version'

Gem::Specification.new do |spec|
  spec.name          = "agx"
  spec.version       = Agx::VERSION
  spec.authors       = ["Bryce Johnston"]
  spec.email         = ["bryce.johnston@hey.com"]

  spec.summary       = %q{Ruby client for accessing agX Platform APIs.}
  spec.description   = %q{Ruby client for accessing Proagrica's agX Platform APIs.}
  spec.homepage      = "https://github.com/cropquest/agx-ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "oj", "< 4"
  spec.add_dependency "oauth2", "< 2"

  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.9"
end