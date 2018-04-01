require 'fourflusher'

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
                              bitcode_enabled)

  deployment_target = target.platform.deployment_target.to_s
  
  target_label = target.label
  Pod::UI.puts "Prebuilding #{target_label}..."
  
  other_options = [] 
  if bitcode_enabled
    other_options += ['OTHER_CFLAGS="-fembed-bitcode"']
  end
  xcodebuild(sandbox, target_label, device, deployment_target, other_options)
  xcodebuild(sandbox, target_label, simulator, deployment_target, other_options + ['ARCHS=x86_64', 'ONLY_ACTIVE_ARCH=NO'])

  root_name = target.pod_name
  module_name = target.product_module_name
  
  executable_path = "#{build_dir}/#{root_name}"
  device_lib = "#{build_dir}/#{CONFIGURATION}-#{device}/#{root_name}/#{module_name}.framework/#{module_name}"
  device_framework_lib = File.dirname(device_lib)
  simulator_lib = "#{build_dir}/#{CONFIGURATION}-#{simulator}/#{root_name}/#{module_name}.framework/#{module_name}"

  return unless File.file?(device_lib) && File.file?(simulator_lib)

  lipo_log = `lipo -create -output #{executable_path} #{device_lib} #{simulator_lib}`
  puts lipo_log unless File.exist?(executable_path)

  FileUtils.mv executable_path, device_lib, :force => true
  output_path.mkpath unless output_path.exist?
  FileUtils.mv device_framework_lib, output_path, :force => true
  FileUtils.rm simulator_lib if File.file?(simulator_lib)
  FileUtils.rm device_lib if File.file?(device_lib)
end

def xcodebuild(sandbox, target, sdk='macosx', deployment_target=nil, other_options=[])
  args = %W(-project #{sandbox.project_path.realdirpath} -scheme #{target} -configuration #{CONFIGURATION} -sdk #{sdk} )
  platform = PLATFORMS[sdk]
  args += Fourflusher::SimControl.new.destination(:oldest, platform, deployment_target) unless platform.nil?
  args += other_options
  Pod::Executable.execute_command 'xcodebuild', args, true
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
    def self.build(sandbox_root_path, target, output_path, bitcode_enabled = false)
    
      return unless not target == nil
    
      sandbox_root = Pathname(sandbox_root_path)
      sandbox = Pod::Sandbox.new(sandbox_root)
      build_dir = self.build_dir(sandbox_root)

      # -- build the framework
      case target.platform.name
      when :ios then build_for_iosish_platform(sandbox, build_dir, output_path, target, 'iphoneos', 'iphonesimulator', bitcode_enabled)
      when :osx then xcodebuild(sandbox, target.label)
      # when :tvos then build_for_iosish_platform(sandbox, build_dir, target, 'appletvos', 'appletvsimulator')
      # when :watchos then build_for_iosish_platform(sandbox, build_dir, target, 'watchos', 'watchsimulator')
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

