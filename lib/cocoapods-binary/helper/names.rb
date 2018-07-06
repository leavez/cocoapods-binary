module Pod

    class Specification

        # Target name is different to spec name. One spec may map to multiple targets due to 
        # included by multiple platforms. This method return the possible names for targets.
        # These name may not be existed actually, It's just a theorical combination.
        def possible_target_names
            suffixes = ["", "-iOS", "-watchOS", "-macOS"]
            paths = suffixes.map do |s|
                self.name + s
            end
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