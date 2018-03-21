
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


module Pod
    class Command
        class Install
            
            # --- patch ---
            old_method = instance_method(:run)
            
            define_method(:run) do 
                Pod::Podfile::DSL.enable_prebuild_patch true
                old_method.bind(self).()
            end

          
        end
    end
end