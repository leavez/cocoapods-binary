require_relative '../tool/tool'

module Pod    
    class Prebuild

        # Pass the data between the 2 steps
        #
        # At step 2, the normal pod install, it needs some info of the
        # prebuilt step. So we store it here.
        #
        class Passer

            # indicate the add/remove/update of prebuit pods
            # @return [Analyzer::SpecsState] 
            #
            class_attr_accessor :prebuild_pods_changes


            # represent the path of resurces to copy
            class ResourcePath
                attr_accessor :real_file_path
                attr_accessor :target_file_path
            end
            # Save the resoures for static framework, and used when installing the prebuild framework
            # static framework needs copy the resurces mannully
            #
            # @return [Hash<String, [Passer::ResourcePath]>]
            class_attr_accessor :resources_to_copy_for_static_framework
            self.resources_to_copy_for_static_framework = {}

            # Some pod won't be build in prebuild stage even if it have `binary=>true`.
            # The targets of this pods have `oshould_build? == true`.
            # We should skip integration (patch spec) for this pods
            #
            # @return [Array<String>]
            class_attr_accessor :target_names_to_skip_integration_framework
            self.target_names_to_skip_integration_framework = []

        end
    end
end