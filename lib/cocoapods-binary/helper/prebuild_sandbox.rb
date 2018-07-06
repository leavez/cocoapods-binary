module Pod
    class PrebuildSandbox < Sandbox

        # [String] standard_sandbox_path
        def self.from_standard_sanbox_path(path)
            prebuild_sandbox_path = Pathname.new(path).realpath + "_Prebuild"
            self.new(prebuild_sandbox_path)
        end

        def self.from_standard_sandbox(sandbox)
            self.from_standard_sanbox_path(sandbox.root)
        end

        def standard_sanbox_path
            self.root.parent
        end
        
        def generate_framework_path
            self.root + "GeneratedFrameworks"
        end

        # @param name [String] pass the target.name (may containing platform suffix)
        # @return [Pathname] the folder containing the framework file.
        def framework_folder_path_for_target_name(name)
            self.generate_framework_path + name
        end

        def exsited_framework_names
            return [] unless generate_framework_path.exist?
            generate_framework_path.children().map do |framework_name|
                if framework_name.directory?
                    if not framework_name.children.empty?
                        File.basename(framework_name)
                    else
                        nil
                    end
                else
                    nil
                end
            end.reject(&:nil?)
        end

        def framework_existed?(root_name)
            return false unless generate_framework_path.exist?
            generate_framework_path.children().any? do |child|
                child.basename.to_s == root_name
            end
        end

    end
end
