
module Pod
    class Installer

        def prebuild_pod_targets

            all = []

            aggregate_targets = self.aggregate_targets.select { |a| a.platform != :watchos }
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