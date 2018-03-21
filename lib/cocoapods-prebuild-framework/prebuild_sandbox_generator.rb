
# hook the `pod` DSL to make it only valid for 'prebuild => true'
module Pod
    class Podfile
        module DSL
            
            @@enable_prebuild_patch = false

            # when enable, `pod` function will skip all pods without 'prebuild => true'
            def self.enable_prebuild_patch(value)
                @@enable_prebuild_patch = value
            end

            # --- patch ---
            old_method = instance_method(:pod)

            define_method(:pod) do |name, *args|
                if !@@enable_prebuild_patch
                    old_method.bind(self).(name, *args)
                    return
                end
                options = args.last
                return unless options.is_a?(Hash)
                prebuild = options[:prebuild_framework]
                if prebuild
                    old_method.bind(self).(name, *args)
                end
            end
         end
    end
end


# hook the install command to install twice (first for the prebuilding)
module Pod
    class Config
        attr_writer :sandbox
    end

    # --- add a force disable option for integral ---
    class Installer
        def self.force_disable_integration(value)
            @@force_disable_integration = value
        end

        old_method = instance_method(:integrate_user_project)
        define_method(:integrate_user_project) do 
            if @@force_disable_integration
                return
            end
            old_method.bind(self).()
        end
    end

    class Command
        class Install

            
            # --- patch ---
            old_method = instance_method(:run)
            
            define_method(:run) do 

                # -- step 1: prebuild framework ---
                
                # enable sikpping for prebuild targets
                Pod::Podfile::DSL.enable_prebuild_patch true
                
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

                # install
                Pod::UI.puts "--- Step 2: pod install ---"
                old_method.bind(self).()
            end
          
        end
    end
end