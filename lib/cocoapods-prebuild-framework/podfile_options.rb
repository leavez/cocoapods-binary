module Pod
    class Podfile
      class TargetDefinition

        ## --- option for setting using prebuild framework ---
        def parse_prebuild_framework(name, requirements)
            options = requirements.last
            return requirements unless options.is_a?(Hash)
    
            should_prebuild_framework = options.delete(:prebuild_framework)
            pod_name = Specification.root_name(name)
            set_prebuild_for_pod(pod_name, should_prebuild_framework)
    
            requirements.pop if options.empty?
        end
        
        def set_prebuild_for_pod(pod_name, should_prebuild)
          return unless should_prebuild == true
          if @prebuild_framework_names.nil? 
            @prebuild_framework_names = []
          end
          @prebuild_framework_names.push pod_name
        end

        def prebuild_framework_names
            @prebuild_framework_names
        end

        # ---- patch method ----
        # We want modify `store_pod` method, but it's hard to insert a line in the 
        # implementation. So we patch a method called in `store_pod`.
        old_method = instance_method(:parse_inhibit_warnings)

        define_method(:parse_inhibit_warnings) do |name, requirements|
          parse_prebuild_framework(name, requirements)
          old_method.bind(self).(name, requirements)
        end
        
      end
    end
end