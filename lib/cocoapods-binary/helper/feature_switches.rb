require_relative '../tool/tool'
require_relative 'prebuild_sandbox'

module Pod

    # a flag that indicate stages
    class_attr_accessor :is_prebuild_stage


    # a switch for the `pod` DSL to make it only valid for ':binary => true'
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

                # patched content
                should_prebuild = Pod::Podfile::DSL.prebuild_all
                local = false
                
                options = args.last
                if options.is_a?(Hash) and options[Pod::Prebuild.keyword] != nil
                    should_prebuild = options[Pod::Prebuild.keyword]
                    local = (options[:path] != nil)
                end
                
                if should_prebuild and (not local)
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

    # a option to disable install complete message
    class Installer
        def self.disable_install_complete_message(value)
            @@disable_install_complete_message = value
        end
        
        old_method = instance_method(:print_post_install_message)
        define_method(:print_post_install_message) do 
            if @@disable_install_complete_message
                return
            end
            old_method.bind(self).()
        end
    end

    # option to disable write lockfiles
    class Config

        @@force_disable_write_lockfile = false
        def self.force_disable_write_lockfile(value)
            @@force_disable_write_lockfile = value
        end
        
        old_method = instance_method(:lockfile_path)
        define_method(:lockfile_path) do 
            if @@force_disable_write_lockfile
                # As config is a singleton, sandbox_root refer to the standard sandbox.
                return PrebuildSandbox.from_standard_sanbox_path(sandbox_root).root + 'Manifest.lock.tmp'
            else
                return old_method.bind(self).()
            end
        end
    end
    
end