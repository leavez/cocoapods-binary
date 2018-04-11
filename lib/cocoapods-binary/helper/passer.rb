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

        end
    end
end