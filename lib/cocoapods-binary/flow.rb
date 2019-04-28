module Pod
    class Prebuild

        # Describe how the binary info transit from podfile's text to
        # pod targets, to framework files, and final to specs
        #
        # This is the core data flow.
        class Flow

            # # BACKGROUND
            #
            # ## ABOUT NAMES
            #
            # There are many kinds of name in cocoapods. Two main names are widely used in this plugin:
            #
            # - root_spec.name (spec.root_name, target.pod_name):
            #   aka "pod_name"
            #   the name we use in podfile. the concept.
            #
            # - target.name:
            #   aka "target_name"
            #   the name of the final target in xcode project. The final real thing.
            #
            # One pod may have multiple targets in xcode project, due to one pod can be used in multiple
            # platform simultaneously. So one `root_spec.name` may have multiple corresponding `target.name`s.
            # Therefore, map a spec to/from targets is a little complicated. It's one to many relation (spec -> targets).
            #
            # Despite the multiple platform, there's another situation to have multiple target, subspec.
            # If 2 targets of same platform in podfile all have Pod A, one have 'A/sub1', 'A/sub2', the other
            # have 'A/sub1', there will be 2 pod targets in Pod.xcodeproj: A-sub1-sub2, A-sub1
            #
            #
            # # OUR RULES
            #
            # For simplicity, we have set 2 rules:
            #
            # 1. Any part of the pod is set to binary, all the pod should be binary
            # 2. Don't support for the different subspec lead to multiple pod targets case.
            #
            #  For the first rule, for example, a subspec is binary while others are not, or in one target is
            #  binary while in another is not. All the source code in this pod should be binary)
            #
            #  For the second rule, it's a limitation. Solving it is not deserved as subspecs may contain duplicated
            #  contents.
            #

            class << self

                # @param [Array<TargetDefinitions>] target_definitions
                # @return [Array<PodTarget>]
                def FROM_target_definitions_TO_prebuild_pod_targets(target_definitions)

                end

                def FROM_prebuild_pod_targets_TO_framework_paths

                end


                # ---------------

                def FROM_target_definitions_TO_prebuild_pod_targets

                end

                def FROM_prebuild_pod_targets_TO_pod_names

                end

                def FROM_pod_name_TO_spec

                end
            end

        end
    end
end