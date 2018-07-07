# ABOUT NAMES
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

# Tool to transform Pod_name to target efficiently
module Pod
    def self.fast_get_targets_for_pod_name(pod_name, targets, cache)
        pod_name_to_targets_hash = nil
        if cache.empty?
            pod_name_to_targets_hash = targets.reduce({}) do |sum, target|
                array = sum[target.pod_name] || []
                array << target
                sum[target.pod_name] = array
                sum
            end
            cache << pod_name_to_targets_hash
        else
            pod_name_to_targets_hash = cache.first
        end
        
        pod_name_to_targets_hash[pod_name] || []
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