require_relative 'feature_switches'

# hook the install command to install twice (first for the prebuilding)
module Pod
    class Config
        attr_writer :sandbox
    end

    class Command
        class Install

            
            # --- patch ---
            old_method = instance_method(:run)
            
            define_method(:run) do 

                # -- step 1: prebuild framework ---
                
                # enable sikpping for prebuild targets
                Pod::Podfile::DSL.enable_prebuild_patch true
                Pod::Prebuild.set_enable_prebuild true
                
                # make another custom sandbox
                standard_sandbox = self.config.sandbox
                prebuild_targets_path = Pathname(standard_sandbox.root).parent + "Pods_prebuild"
                self.config.sandbox = Pod::Sandbox.new(prebuild_targets_path)
                
                # don't integrate targets
                Pod::Installer.force_disable_integration true
                
                # install
                Pod::UI.puts "--- Step 1: prebuild framework ---"
                old_method.bind(self).()

                
                # -- step 2: prebuild framework ---

                # reset the environment
                self.config.podfile = nil
                self.config.sandbox = standard_sandbox
                Pod::Installer.force_disable_integration false
                Pod::Podfile::DSL.enable_prebuild_patch false
                Pod::Prebuild.set_enable_prebuild false

                # install
                Pod::UI.puts "--- Step 2: pod install ---"
                old_method.bind(self).()
            end
          
        end
    end
end