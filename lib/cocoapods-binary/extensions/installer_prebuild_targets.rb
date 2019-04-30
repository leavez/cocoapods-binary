require_relative '../data_flow'
require_relative '../helper/context'

module Pod
    class Installer

        # Get the all the prebuild targets
        # It can only be called at the prebuild installer
        #
        # @return [Array<PodTarget>]
        def prebuild_pod_targets
            assert Prebuild::Context.in_prebuild_stage
            @prebuild_pod_targets ||= (
                Prebuild::DataFlow.instance.get_prebuild_targets(self.podfile, self.pod_targets)
            )
        end





        def __prebuild_pod_targets
            @prebuild_pod_targets ||= (
            all = []

            aggregate_targets = self.aggregate_targets
            aggregate_targets.each do |aggregate_target|
                target_definition = aggregate_target.target_definition
                targets = aggregate_target.pod_targets || []

                # filter prebuild
                prebuild_names = target_definition.prebuild_framework_pod_names
                if not Podfile::DSL.prebuild_all
                    targets = targets.select { |pod_target| prebuild_names.include?(pod_target.pod_name) }
                end
                dependency_targets = targets.map {|t| t.recursive_dependent_targets }.flatten.uniq || []
                targets = (targets + dependency_targets).uniq

                # filter should not prebuild
                explict_should_not_names = target_definition.should_not_prebuild_framework_pod_names
                targets = targets.reject { |pod_target| explict_should_not_names.include?(pod_target.pod_name) }

                all += targets
            end

            all = all.reject {|pod_target| sandbox.local?(pod_target.pod_name) }
            all.uniq
            )
        end

        # the root names who needs prebuild, including dependency pods.
        def prebuild_pod_names
            @prebuild_pod_names ||= self.__prebuild_pod_targets.map(&:pod_name)
        end


        def validate_every_pod_only_have_one_form

            multi_targets_pods = self.pod_targets.group_by do |t|
                t.pod_name
            end.select do |k, v|
                v.map{|t| t.platform.name }.count > 1
            end

            multi_targets_pods = multi_targets_pods.reject do |name, targets|
                contained = targets.map{|t| self.__prebuild_pod_targets.include? t }
                contained.uniq.count == 1 # all equal
            end

            return if multi_targets_pods.empty?

            warnings = "One pod can only be prebuilt or not prebuilt. These pod have different forms in multiple targets:\n"
            warnings += multi_targets_pods.map{|name, targets| "         #{name}: #{targets.map{|t|t.platform.name}}"}.join("\n")
            raise Informative, warnings
        end

    end
end


