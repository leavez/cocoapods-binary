# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-binary/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-binary'
  spec.version       = CocoapodsBinary::VERSION
  spec.authors       = ['leavez']
  spec.email         = ['gaojiji@gmail.com']
  spec.description   = %q{A short description of cocoapods-binary.}
  spec.summary       = %q{A longer description of cocoapods-binary.}
  spec.homepage      = 'https://github.com/EXAMPLE/cocoapods-binary'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/).reject{|f| f.start_with? "test/"}
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency "cocoapods", ">= 1.4.0", "< 2.0"
  spec.add_dependency "fourflusher", "~> 2.0"

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
