Pod::HooksManager.register('cocoapods-prebuild-framework', :pre_install) do |installer_context|
  podfile = installer_context.podfile
  podfile.use_frameworks!
end
