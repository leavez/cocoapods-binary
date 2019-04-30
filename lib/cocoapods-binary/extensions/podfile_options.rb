module Pod

    class Prebuild
        def self.keyword
            :binary
        end
    end

    class Podfile
      class TargetDefinition

        ## --- option for setting using prebuild framework ---
        def parse_prebuild_framework(name, requirements)
            should_prebuild = Pod::Podfile::DSL.prebuild_all

            options = requirements.last
            if options.is_a?(Hash) && options[Pod::Prebuild.keyword] != nil 
                should_prebuild = options.delete(Pod::Prebuild.keyword)
                requirements.pop if options.empty?
            end
    
            pod_name = Specification.root_name(name)
            set_prebuild_for_pod(pod_name, should_prebuild)
        end
        
        def set_prebuild_for_pod(pod_name, should_prebuild)

            if should_prebuild == true
                @prebuild_framework_pod_names ||= []
                @prebuild_framework_pod_names.push pod_name
            else
                @should_not_prebuild_framework_pod_names ||= []
                @should_not_prebuild_framework_pod_names.push pod_name
            end
        end

        def prebuild_framework_pod_names(inherent_parent: true)
            names = @prebuild_framework_pod_names || []
            if inherent_parent && parent != nil and parent.kind_of? TargetDefinition
                names += parent.prebuild_framework_pod_names
            end
            names
        end
        def should_not_prebuild_framework_pod_names(inherent_parent: true)
            names = @should_not_prebuild_framework_pod_names || []
            if inherent_parent && parent != nil and parent.kind_of?(TargetDefinition)
                names += parent.should_not_prebuild_framework_pod_names
            end
            names
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


