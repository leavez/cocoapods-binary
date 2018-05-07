# update version
version = ARGV[0]
if version == nil 
    puts "please input a version"
    exit
end
path = "lib/cocoapods-binary/gem_version.rb"
content = <<-eos
module CocoapodsBinary
    VERSION = "#{version}"
end
eos
File.write(path, content)

`git add -A; git commit -m "bump version"; git push`
`rake install`
`gem push pkg/cocoapods-binary-#{version}.gem`
