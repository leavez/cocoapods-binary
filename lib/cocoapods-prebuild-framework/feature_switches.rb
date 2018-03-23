module Pod

    # a flag that indicate stages
    def self.is_prebuild_stage
        @@is_prebuild_stage
    end
    def self.set_is_prebuild_stage(value)
        @@is_prebuild_stage = value
    end

    # a switch for the `pod` DSL to make it only valid for 'prebuild => true'
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
    
    
    # a force disable option for integral 
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

    # option to disable write lockfiles
    class Config
        def self.force_disable_write_lockfile(value)
            @@force_disable_write_lockfile = value
        end
        
        old_method = instance_method(:lockfile_path)
        define_method(:lockfile_path) do 
            if @@force_disable_write_lockfile
                return self.sandbox.root + 'Manifest.lock.bak'
            else
                return old_method.bind(self).()
            end
        end
    end
    
    # a option to control the Rome buiding functionality
    class Prebuild
        def self.set_enable_prebuild(value)
            @@enable_prebuild = value
        end
        def self.prebuild_enabled
            @@enable_prebuild
        end
    end
end