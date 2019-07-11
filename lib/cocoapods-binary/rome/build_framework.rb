require 'fourflusher'
require 'xcpretty'

CONFIGURATION = "Release"
PLATFORMS = { 'iphonesimulator' => 'iOS',
              'appletvsimulator' => 'tvOS',
              'watchsimulator' => 'watchOS' }

#  Build specific target to framework file
#  @param [PodTarget] target
#         a specific pod target
#
def build_for_iosish_platform(sandbox, 
                              build_dir, 
                              output_path,
                              target, 
                              device, 
                              simulator,
                              bitcode_enabled,
                              custom_build_options = [], # Array<String>
                              custom_build_options_simulator = [] # Array<String>
                              )

  deployment_target = target.platform.deployment_target.to_s
  
  target_label = target.label # name with platform if it's used in multiple platforms
  Pod::UI.puts "Prebuilding #{target_label}..."
  
  other_options = []
  # bitcode enabled
  other_options += ['BITCODE_GENERATION_MODE=bitcode'] if bitcode_enabled
  # make less arch to iphone simulator for faster build
  custom_build_options_simulator += ['ARCHS=x86_64', 'ONLY_ACTIVE_ARCH=NO'] if simulator == 'iphonesimulator'

  is_succeed, _ = xcodebuild(sandbox, target_label, device, deployment_target, other_options + custom_build_options)
  exit 1 unless is_succeed
  is_succeed, _ = xcodebuild(sandbox, target_label, simulator, deployment_target, other_options + custom_build_options_simulator)
  exit 1 unless is_succeed

  # paths
  target_name = target.name # equals target.label, like "AFNeworking-iOS" when AFNetworking is used in multiple platforms.
  module_name = target.product_module_name
  device_framework_path = "#{build_dir}/#{CONFIGURATION}-#{device}/#{target_name}/#{module_name}.framework"
  simulator_framework_path = "#{build_dir}/#{CONFIGURATION}-#{simulator}/#{target_name}/#{module_name}.framework"
  output_framework_path = "#{output_path}/#{module_name}.framework"

  device_binary = device_framework_path + "/#{module_name}"
  simulator_binary = simulator_framework_path + "/#{module_name}"
  return unless File.file?(device_binary) && File.file?(simulator_binary)
  
  # the device_lib path is the final output file path
  # combine the binaries
  tmp_lipoed_binary_path = "#{build_dir}/#{target_name}"
  lipo_log = `lipo -create -output #{tmp_lipoed_binary_path} #{device_binary} #{simulator_binary}`
  puts lipo_log unless File.exist?(tmp_lipoed_binary_path)
  FileUtils.mv tmp_lipoed_binary_path, device_binary, :force => true
  
  # collect the swiftmodule file for various archs.
  device_swiftmodule_path = device_framework_path + "/Modules/#{module_name}.swiftmodule"
  simulator_swiftmodule_path = simulator_framework_path + "/Modules/#{module_name}.swiftmodule"
  if File.exist?(device_swiftmodule_path)
    FileUtils.cp_r simulator_swiftmodule_path + "/.", device_swiftmodule_path
  end

  # combine the generated swift headers
  # (In xcode 10.2, the generated swift headers vary for each archs)
  # https://github.com/leavez/cocoapods-binary/issues/58
  simulator_generated_swift_header_path = simulator_framework_path + "/Headers/#{module_name}-Swift.h"
  device_generated_swift_header_path = device_framework_path + "/Headers/#{module_name}-Swift.h"
  if File.exist? simulator_generated_swift_header_path
    device_header = File.read(device_generated_swift_header_path)
    simulator_header = File.read(simulator_generated_swift_header_path)
    # https://github.com/Carthage/Carthage/issues/2718#issuecomment-473870461
    combined_header_content = %Q{
#if TARGET_OS_SIMULATOR // merged by cocoapods-binary

#{simulator_header}

#else // merged by cocoapods-binary

#{device_header}

#endif // merged by cocoapods-binary
}
    File.write(device_generated_swift_header_path, combined_header_content.strip)
  end

  # handle the dSYM files
  device_dsym = "#{device_framework_path}.dSYM"
  device_dsym_output_path = "#{output_framework_path}.dSYM"
  if File.exist? device_dsym
    # lipo the simulator dsym
    simulator_dsym = "#{simulator_framework_path}.dSYM"
    if File.exist? simulator_dsym
      tmp_lipoed_binary_path = "#{output_path}/#{module_name}.draft"
      lipo_log = `lipo -create -output #{tmp_lipoed_binary_path} #{device_dsym}/Contents/Resources/DWARF/#{module_name} #{simulator_dsym}/Contents/Resources/DWARF/#{module_name}`
      puts lipo_log unless File.exist?(tmp_lipoed_binary_path)
      FileUtils.mv tmp_lipoed_binary_path, "#{device_framework_path}.dSYM/Contents/Resources/DWARF/#{module_name}", :force => true
    end
    # move
    FileUtils.rm_r device_dsym_output_path if Dir.exist? device_dsym_output_path
    File.rename device_dsym, device_dsym_output_path
  end

  # output
  output_path.mkpath unless output_path.exist?
  FileUtils.rm_r output_framework_path if Dir.exist? output_framework_path
  File.rename device_framework_path, output_framework_path

end

def xcodebuild(sandbox, target, sdk='macosx', deployment_target=nil, other_options=[])
  args = %W(-project #{sandbox.project_path.realdirpath} -scheme #{target} -configuration #{CONFIGURATION} -sdk #{sdk} )
  platform = PLATFORMS[sdk]
  args += Fourflusher::SimControl.new.destination(:oldest, platform, deployment_target) unless platform.nil?
  args += other_options
  log = `xcodebuild #{args.join(" ")} 2>&1`
  exit_code = $?.exitstatus  # Process::Status
  is_succeed = (exit_code == 0)

  if !is_succeed
    begin
        if log.include?('** BUILD FAILED **')
            # use xcpretty to print build log
            # 64 represent command invalid. http://www.manpagez.com/man/3/sysexits/
            printer = XCPretty::Printer.new({:formatter => XCPretty::Simple, :colorize => 'auto'})
            log.each_line do |line|
              printer.pretty_print(line)
            end
        else
            raise "shouldn't be handle by xcpretty"
        end
    rescue
        puts log.red
    end
  end
  [is_succeed, log]
end



module Pod
  class Prebuild

    # Build the frameworks with sandbox and targets
    #
    # @param  [String] sandbox_root_path
    #         The sandbox root path where the targets project place
    #         
    #         [PodTarget] target
    #         The pod targets to build
    #
    #         [Pathname] output_path
    #         output path for generated frameworks
    #
    def self.build(sandbox_root_path, target, output_path, bitcode_enabled = false, custom_build_options=[], custom_build_options_simulator=[])
    
      return if target.nil?
    
      sandbox_root = Pathname(sandbox_root_path)
      sandbox = Pod::Sandbox.new(sandbox_root)
      build_dir = self.build_dir(sandbox_root)

      # -- build the framework
      case target.platform.name
      when :ios then build_for_iosish_platform(sandbox, build_dir, output_path, target, 'iphoneos', 'iphonesimulator', bitcode_enabled, custom_build_options, custom_build_options_simulator)
      when :osx then xcodebuild(sandbox, target.label, 'macosx', nil, custom_build_options)
      # when :tvos then build_for_iosish_platform(sandbox, build_dir, target, 'appletvos', 'appletvsimulator')
      when :watchos then build_for_iosish_platform(sandbox, build_dir, output_path, target, 'watchos', 'watchsimulator', true, custom_build_options, custom_build_options_simulator)
      else raise "Unsupported platform for '#{target.name}': '#{target.platform.name}'" end
    
      raise Pod::Informative, 'The build directory was not found in the expected location.' unless build_dir.directory?

      # # --- copy the vendored libraries and framework
      # frameworks = build_dir.children.select{ |path| File.extname(path) == ".framework" }
      # Pod::UI.puts "Built #{frameworks.count} #{'frameworks'.pluralize(frameworks.count)}"
    
      # pod_target = target
      # consumer = pod_target.root_spec.consumer(pod_target.platform.name)
      # file_accessor = Pod::Sandbox::FileAccessor.new(sandbox.pod_dir(pod_target.pod_name), consumer)
      # frameworks += file_accessor.vendored_libraries
      # frameworks += file_accessor.vendored_frameworks

      # frameworks.uniq!
    
      # frameworks.each do |framework|
      #   FileUtils.mkdir_p destination
      #   FileUtils.cp_r framework, destination, :remove_destination => true
      # end
      # build_dir.rmtree if build_dir.directory?
    end
    
    def self.remove_build_dir(sandbox_root)
      path = build_dir(sandbox_root)
      path.rmtree if path.exist?
    end

    private 
    
    def self.build_dir(sandbox_root)
      # don't know why xcode chose this folder
      sandbox_root.parent + 'build' 
    end

  end
end
