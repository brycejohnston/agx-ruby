# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'agx/version'

Gem::Specification.new do |spec|
  spec.name          = "agx"
  spec.version       = Agx::VERSION
  spec.authors       = ["Bryce Johnston"]
  spec.email         = ["johnstonbrc@gmail.com"]

  spec.summary       = %q{Ruby client for accessing agX Platform APIs.}
  spec.description   = %q{Ruby client for accessing SST Software's agX Platform APIs.}
  spec.homepage      = "https://github.com/brycejohnston/agx-ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "oj", "~> 2.18"
  spec.add_dependency "oauth2", "~> 1.3.1"

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
