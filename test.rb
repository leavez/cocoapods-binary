require 'cocoapods-binary/gem_version.rb'
# build gem
puts " 💫 begin build [cocoapods-binary]...\n"
build_ret = %x(gem build cocoapods-binary.gemspec)

# build success
if ( build_ret.downcase =~ /(.*)successfully(.*)/ )
    puts "\n✅ build [cocoapods-binary] successfully!"

    gemFile = /cocoapods-binary-.*/.match(build_ret)    # match gem file
    puts "\n💫 begin install #{gemFile} ...\n"
    install_ret = %x(sudo gem install #{gemFile})       # install gem file

    if (install_ret.downcase =~ /(.*)successfully installed cocoapods-binary-(.*)/)
        Dir::chdir("demo")
        puts "\n✅ install gem success.\n\n💫 Begin run `Pod install`"
        puts "#{%x(pod install)}"   # pod install
    else 
        puts "❗️install #{gemFile} failed！"
    end
else 
    puts "❗️build [cocoapods-binary] failed!"
end


