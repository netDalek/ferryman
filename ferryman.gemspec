# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ferryman/version'

Gem::Specification.new do |spec|
  spec.name          = "ferryman"
  spec.version       = Ferryman::VERSION
  spec.authors       = ["Denis Kirichenko"]
  spec.email         = ["d.kirichenko@fun-box.ru"]
  spec.description   = %q{Ferryman}
  spec.summary       = %q{Ferryman}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "redis"
  spec.add_runtime_dependency "json-rpc-objects"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry"
end
