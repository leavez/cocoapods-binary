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
            options = requirements.last
            return requirements unless options.is_a?(Hash)
    
            should_prebuild_framework = options.delete(Pod::Prebuild.keyword)
            pod_name = Specification.root_name(name)
            set_prebuild_for_pod(pod_name, should_prebuild_framework)
            requirements.pop if options.empty?
        end
        
        def set_prebuild_for_pod(pod_name, should_prebuild)
            
            if should_prebuild == true
                # watchos isn't supported currently
                return if self.platform.name == :watchos

                @prebuild_framework_names ||= []
                @prebuild_framework_names.push pod_name
            else
                @should_not_prebuild_framework_names ||= []
                @should_not_prebuild_framework_names.push pod_name
            end
        end

        def prebuild_framework_names
            names = @prebuild_framework_names || []
            if parent != nil and parent.kind_of? TargetDefinition
                names += parent.prebuild_framework_names
            end
            names
        end
        def should_not_prebuild_framework_names
            names = @should_not_prebuild_framework_names || []
            if parent != nil and parent.kind_of? TargetDefinition
                names += parent.should_not_prebuild_framework_names
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


module Pod
    class Installer

        def prebuild_pod_targets

            all = []

            aggregate_targets = self.aggregate_targets.select { |a| a.platform.name != :watchos }
            aggregate_targets.each do |aggregate_target|
                target_definition = aggregate_target.target_definition
                targets = aggregate_target.pod_targets || []

                # filter prebuild
                prebuild_names = target_definition.prebuild_framework_names
                if not Podfile::DSL.prebuild_all
                    targets = targets.select { |pod_target| prebuild_names.include?(pod_target.pod_name) } 
                end
                dependency_targets = targets.map {|t| t.recursive_dependent_targets }.flatten.uniq || []
                targets = (targets + dependency_targets).uniq

                # filter should not prebuild
                explict_should_not_names = target_definition.should_not_prebuild_framework_names
                targets = targets.reject { |pod_target| explict_should_not_names.include?(pod_target.pod_name) } 

                all += targets
            end

            all = all.reject {|pod_target| sandbox.local?(pod_target.pod_name) }
            all.uniq
        end

        # the root names who needs prebuild, including dependency pods.
        def prebuild_pod_names 
           @prebuild_pod_names ||= self.prebuild_pod_targets.map(&:pod_name)
        end

    end
end



