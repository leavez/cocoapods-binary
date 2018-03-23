module Pod
    class Prebuild
        class Path
            def self.convert_to_pathname_if_needed(path)
                return path if path.kind_of? Pathname
                Pathnanme(path)
            end

            def self.prebuild_sanbox_path(standard_sandbox_path)
                convert_to_pathname_if_needed(standard_sandbox_path) + "_Prebuild"
            end

            def self.generated_frameworks_destination(sandbox_path)
                convert_to_pathname_if_needed(sandbox_path) + 'Frameworks'
            end
        end
    end
end