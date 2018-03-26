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
        
        def generate_framework_path
            self.root + "Frameworks"
        end

        def framework_path_for_pod_name(name)
            self.generate_framework_path + "#{name}.framework"
        end

        def exsited_framework_names
            return [] unless generate_framework_path.exist?
            generate_framework_path.children.map do |framework_name|
                extension = File.extname(framework_name)
                if extension == ".framework"
                    File.basename(framework_name, extension)
                else
                    nil
                end
            end.reject(&:nil?)
        end
    end
end
