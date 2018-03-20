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


module Pod
    class Installer
      class PostInstallHooksContext

        attr_accessor :aggregate_targets

        # ---- patch method ----
        def self.generate(sandbox, aggregate_targets)
            # -- copy from original code --
            umbrella_targets_descriptions = []
            aggregate_targets.each do |umbrella|
              desc = UmbrellaTargetDescription.new
              desc.user_project = umbrella.user_project
              desc.user_targets = umbrella.user_targets
              desc.specs = umbrella.specs
              desc.platform_name = umbrella.platform.name
              desc.platform_deployment_target = umbrella.platform.deployment_target.to_s
              desc.cocoapods_target_label = umbrella.label
              umbrella_targets_descriptions << desc
            end
    
            result = new
            result.sandbox_root = sandbox.root.to_s
            result.pods_project = sandbox.project
            result.sandbox = sandbox
            result.umbrella_targets = umbrella_targets_descriptions
            # -- \copy from original code --
            
            result.aggregate_targets = aggregate_targets
            result
        end


      end
    end
end

