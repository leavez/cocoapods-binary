require 'bundler/gem_tasks'

desc 'Runs all the tests'
task :specs do
  Dir.chdir('test') do
    system 'sh test.sh'
  end
end

# rake bump_version 1.0.1
desc 'bump version number'
task :bump_version do
  version = ARGV[1]

  unless version
    puts 'please input a version'
    exit(1)
  end

  content = <<-DOC
module CocoapodsBinary
  VERSION = "#{version}"
end
  DOC
  File.write('lib/cocoapods-binary/gem_version.rb', content)
  `git add -A; git commit -m "bump version"; git push`
  `rake install`
  `gem push pkg/cocoapods-binary-#{version}.gem`
  exit
end

task default: :specs
