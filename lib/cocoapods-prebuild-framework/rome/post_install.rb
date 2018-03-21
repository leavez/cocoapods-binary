require 'fourflusher'
require_relative '../feature_switches'
require_relative '../path'


CONFIGURATION = "Release"
PLATFORMS = { 'iphonesimulator' => 'iOS',
              'appletvsimulator' => 'tvOS',
              'watchsimulator' => 'watchOS' }

def build_for_iosish_platform(sandbox, build_dir, target, device, simulator)
  deployment_target = target.platform.deployment_target.to_s
  
  pod_targets = target.prebuild_pod_targets
  pod_targets.each do |target|
    target_label = target.label
    Pod::UI.puts "Prebuilding #{target_label} ..."
    xcodebuild(sandbox, target_label, device, deployment_target)
    xcodebuild(sandbox, target_label, simulator, deployment_target)
  end


  spec_names = pod_targets.map { |pod_target| [pod_target.pod_name,  pod_target.product_module_name ] }.uniq

  spec_names.each do |root_name, module_name|
    executable_path = "#{build_dir}/#{root_name}"
    device_lib = "#{build_dir}/#{CONFIGURATION}-#{device}/#{root_name}/#{module_name}.framework/#{module_name}"
    device_framework_lib = File.dirname(device_lib)
    simulator_lib = "#{build_dir}/#{CONFIGURATION}-#{simulator}/#{root_name}/#{module_name}.framework/#{module_name}"

    next unless File.file?(device_lib) && File.file?(simulator_lib)

    lipo_log = `lipo -create -output #{executable_path} #{device_lib} #{simulator_lib}`
    puts lipo_log unless File.exist?(executable_path)

    FileUtils.mv executable_path, device_lib, :force => true
    FileUtils.mv device_framework_lib, build_dir, :force => true
    FileUtils.rm simulator_lib if File.file?(simulator_lib)
    FileUtils.rm device_lib if File.file?(device_lib)
  end
end

def xcodebuild(sandbox, target, sdk='macosx', deployment_target=nil)
  args = %W(-project #{sandbox.project_path.realdirpath} -scheme #{target} -configuration #{CONFIGURATION} -sdk #{sdk})
  platform = PLATFORMS[sdk]
  args += Fourflusher::SimControl.new.destination(:oldest, platform, deployment_target) unless platform.nil?
  Pod::Executable.execute_command 'xcodebuild', args, true
end

Pod::HooksManager.register('cocoapods-prebuild-framework', :post_install) do |installer_context|

  next unless Pod::Prebuild.prebuild_enabled

  sandbox_root = Pathname(installer_context.sandbox_root)
  sandbox = Pod::Sandbox.new(sandbox_root)

  build_dir = sandbox_root.parent + 'build'
  destination = Pod::Prebuild::Path.generated_frameworks_destination(sandbox_root)

  
  build_dir.rmtree if build_dir.directory?
  aggregate_targets = installer_context.aggregate_targets.select do |t|
    t.have_prebuild_pod_targets?
  end

  Pod::UI.puts "Prebuild frameworks (total #{aggregate_targets.count})"

  aggregate_targets.each do |aggregate_target|
    case aggregate_target.platform.name
    when :ios then build_for_iosish_platform(sandbox, build_dir, aggregate_target, 'iphoneos', 'iphonesimulator')
    when :osx then xcodebuild(sandbox, aggregate_target.label)
    when :tvos then nil
    when :watchos then nil
    # when :tvos then build_for_iosish_platform(sandbox, build_dir, target, 'appletvos', 'appletvsimulator')
    # when :watchos then build_for_iosish_platform(sandbox, build_dir, target, 'watchos', 'watchsimulator')
    else raise "Unknown platform '#{aggregate_target.platform.name}'" end
  end

  raise Pod::Informative, 'The build directory was not found in the expected location.' unless build_dir.directory?

  # Make sure the device target overwrites anything in the simulator build, otherwise iTunesConnect
  # can get upset about Info.plist containing references to the simulator SDK
  frameworks = Pathname.glob("build/*.framework").reject { |f| f.to_s =~ /Pods.*\.framework/ }
  Pod::UI.puts "Built #{frameworks.count} #{'frameworks'.pluralize(frameworks.count)}"

  destination.rmtree if destination.directory?

  aggregate_targets.each do |aggregate_target|
    aggregate_target.prebuild_pod_targets.each do |pod_target|
      consumer = pod_target.root_spec.consumer(aggregate_target.platform.name)
      file_accessor = Pod::Sandbox::FileAccessor.new(sandbox.pod_dir(pod_target.pod_name), consumer)
      frameworks += file_accessor.vendored_libraries
      frameworks += file_accessor.vendored_frameworks
    end
  end
  frameworks.uniq!

  Pod::UI.puts "Copying #{frameworks.count} #{'frameworks'.pluralize(frameworks.count)} " \
    "to `#{destination.relative_path_from Pathname.pwd}`"

  frameworks.each do |framework|
    FileUtils.mkdir_p destination
    FileUtils.cp_r framework, destination, :remove_destination => true
  end
  build_dir.rmtree if build_dir.directory?
end
