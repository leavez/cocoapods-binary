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
            
            @prebuild_framework_names ||= []
            @prebuild_framework_names.push pod_name
            puts "true: #{self.prebuild_framework_names}"
            puts self
        end

        def prebuild_framework_names
            @prebuild_framework_names || []
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


module Pod
    class Installer
        def prebuild_pod_names 
            @prebuild_pod_names unless @prebuild_pod_names.nil? 
            names = self.aggregate_targets.reduce([]) do |sum, element|
                sum + element.target_definition.prebuild_framework_names
            end
            @prebuild_pod_names = names
            names
        end
    end
end

module Pod
    class AggregateTarget

        def have_prebuild_pod_targets?
            prebuild_framework_names = self.target_definition.prebuild_framework_names
            return (prebuild_framework_names != nil and !prebuild_framework_names.empty?)
        end

        def prebuild_pod_targets
            prebuild_framework_names = self.target_definition.prebuild_framework_names
            pod_targets = self.pod_targets.select { |pod_target| prebuild_framework_names.include?(pod_target.pod_name) }
            return pod_targets
        end
    end
end

