# encoding: UTF-8

require_relative 'feature_switches'
require_relative 'prebuild_sandbox'

Pod::HooksManager.register('cocoapods-binary', :pre_install) do |installer_context|
    
    # check user_framework is on
    podfile = installer_context.podfile
    podfile.target_definition_list.each do |target_definition|
        next if target_definition.prebuild_framework_names.empty?
        if not target_definition.uses_frameworks?
            STDERR.puts "[!] Cocoapods-binary requires `use_frameworks!`".red
            exit
        end
    end
end

# hook the install command to install twice (first for the prebuilding)
module Pod
    class Config
        attr_writer :sandbox
        attr_writer :lockfile
    end

    class Command
        class Install

            
            # --- patch ---
            old_method = instance_method(:run)
            
            define_method(:run) do 

                # -- step 1: prebuild framework ---

                # control features
                Pod.is_prebuild_stage = true
                Pod::Podfile::DSL.enable_prebuild_patch true  # enable sikpping for prebuild targets
                Pod::Installer.force_disable_integration true # don't integrate targets
                Pod::Config.force_disable_write_lockfile true # disbale write lock file for perbuild podfile
                Pod::Installer.disable_install_complete_message true # disable install complete message

                # make another custom sandbox
                standard_sandbox = self.config.sandbox
                prebuild_sandbox = Pod::PrebuildSandbox.from_standard_sandbox(standard_sandbox)
                self.config.sandbox = prebuild_sandbox
                
                # install
                Pod::UI.puts "✔️  Prebuild frameworks"
                old_method.bind(self).()

                
                # -- step 2: prebuild framework ---

                # reset the environment
                self.config.podfile = nil
                self.config.lockfile = nil
                self.config.sandbox = standard_sandbox
                Pod.is_prebuild_stage = false
                Pod::Installer.force_disable_integration false
                Pod::Podfile::DSL.enable_prebuild_patch false
                Pod::Config.force_disable_write_lockfile false
                Pod::Installer.disable_install_complete_message false

                # install
                Pod::UI.puts "\n"
                Pod::UI.puts "✔️  Pod Install"
                old_method.bind(self).()
            end
          
        end
    end
end