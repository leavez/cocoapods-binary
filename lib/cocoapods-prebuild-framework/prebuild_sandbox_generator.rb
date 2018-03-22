require_relative 'feature_switches'
require_relative 'path'

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
                Pod::Podfile::DSL.enable_prebuild_patch true  # enable sikpping for prebuild targets
                Pod::Prebuild.set_enable_prebuild true        # enable prebuid action
                Pod::Installer.force_disable_integration true # don't integrate targets
                Pod::Config.force_disable_write_lockfile true # disbale write lock file for perbuild podfile

                # make another custom sandbox
                standard_sandbox = self.config.sandbox
                prebuild_targets_path = Pod::Prebuild::Path.sanbox_path(standard_sandbox.root)
                self.config.sandbox = Pod::Sandbox.new(prebuild_targets_path)
                
                # install
                Pod::UI.puts "--- Step 1: prebuild framework ---"
                old_method.bind(self).()

                
                # -- step 2: prebuild framework ---

                # reset the environment
                self.config.podfile = nil
                self.config.lockfile = nil
                self.config.sandbox = standard_sandbox
                Pod::Installer.force_disable_integration false
                Pod::Podfile::DSL.enable_prebuild_patch false
                Pod::Prebuild.set_enable_prebuild false
                Pod::Config.force_disable_write_lockfile false

                # install
                Pod::UI.puts "--- Step 2: pod install ---"
                old_method.bind(self).()
            end
          
        end
    end
end