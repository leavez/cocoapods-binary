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
            return unless should_prebuild == true
            @prebuild_framework_names ||= []
            @prebuild_framework_names.push pod_name
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
        private
        # the root names who needs prebuild, just the ones specified in podfile, excluding dependency pods.
        def raw_prebuild_pod_names
            self.podfile.target_definition_list.map(&:prebuild_framework_names).flatten.uniq
        end

        
        public 

        def prebuild_pod_targets
            names = raw_prebuild_pod_names
            targets = self.pod_targets.select { |pod_target| names.include?(pod_target.pod_name) } || []
            dependency_targets = targets.map {|t| t.recursive_dependent_targets }.flatten.uniq || []
            all = targets + dependency_targets
            all
        end

        # the root names who needs prebuild, including dependency pods.
        def prebuild_pod_names 
           @prebuild_pod_names ||= self.prebuild_pod_targets.map(&:pod_name)
        end

    end
end



