# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-prebuild-framework/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-prebuild-framework'
  spec.version       = CocoapodsPrebuildFramework::VERSION
  spec.authors       = ['leavez']
  spec.email         = ['gaojiji@gmail.com']
  spec.description   = %q{A short description of cocoapods-prebuild-framework.}
  spec.summary       = %q{A longer description of cocoapods-prebuild-framework.}
  spec.homepage      = 'https://github.com/EXAMPLE/cocoapods-prebuild-framework'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency "cocoapods", ">= 1.4.0", "< 2.0"
  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
