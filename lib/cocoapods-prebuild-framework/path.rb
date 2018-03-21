module Pod
    class Prebuild
        class Path
            def self.sanbox_path(standard_sandbox_path)
                prebuild_targets_path = Pathname(standard_sandbox_path).parent + "Pods(Prebuild)"
            end
            def self.generated_frameworks_destination(sandbox_path)
                sandbox_path + 'Prebuild-Frameworks'
            end
        end
    end
end