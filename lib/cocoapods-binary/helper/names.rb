#
# There are many kinds of name in cocoapods. Two main names are widely used in this plugin.
# - root_spec.name (spec.root_name, targe.pod_name):
#   aka "pod_name"
#   the name we use in podfile. the concept.
# 
# - target.name:
#   aka "target_name"
#   the name of the final target in xcode project. the final real thing.
#
# One pod may have multiple targets in xcode project, due to one pod can be used in mutiple 
# platform simultaneously. So one `root_spec.name` may have multiple coresponding `target.name`s.
# Therefore, map a spec to/from targets is a little complecated. It's one to many.
#
module Pod

    def self.possible_target_names_from_pod_name(root_pod_name) 
        suffixes = ["", "-iOS", "-watchOS", "-macOS"]
        paths = suffixes.map do |s|
            root_pod_name + s
        end
    end

    def self.pod_name_from_target_name(target_name)
        suffixes = ["-iOS", "-watchOS", "-macOS"]
        for s in suffixes
            if target_name.end_with? s
                return target_name.chomp s
            end
        end
        return target_name
    end

    class Specification

        # Target name is different to spec name. One spec may map to multiple targets due to 
        # included by multiple platforms. This method return the possible names for targets.
        # These name may not be existed actually, It's just a theorical combination.
        def possible_target_names
            Pod.possible_target_names_from_pod_name self.name
        end

        # return the real targets names generated in prebuild sandbox
        def prebuild_target_names_in_prebuild_sandbox(prebuild_sandbox)
            names = self.possible_target_names
            names.select do |name|
                path = prebuild_sandbox.framework_folder_path_for_target_name(name)
                path.exist?
            end
        end
    end

end

# Target:
   
#     def pod_name
#       root_spec.name
#     end

#     def name
# 	    pod_name + #{scope_suffix}
#     end	

#     def product_module_name
#       root_spec.module_name
#     end
  
#     def framework_name
#       "#{product_module_name}.framework"
#     end

#    def product_name
#       if requires_frameworks?
#         framework_name
#       else
#         static_library_name
#       end
#     end

#     def product_basename
#       if requires_frameworks?
#         product_module_name
#       else
#         label
#       end
#     end

#     def framework_name
#       "#{product_module_name}.framework"
#     end