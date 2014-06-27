# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ensembl/version'

Gem::Specification.new do |spec|
  spec.name          = "ensembl"
  spec.version       = Ensembl::VERSION
  spec.authors       = ["Kristjan Metsalu"]
  spec.email         = ["kristjan.metsalu@ut.ee"]
  spec.summary       = %q{ Gem to access Ensembl.org databases through API }
  spec.description   = %q{ ensembl provides an ruby API to connect to ensembl databases. }
  spec.homepage      = "https://github.com/kmetsalu/ensembl"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '~> 2.0'

  spec.add_dependency 'mysql2', '~> 0.3'
  spec.add_dependency 'activerecord', '~> 4.1'

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", '~> 10.3'
end
