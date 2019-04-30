require_relative '../extensions/podfile_options'

module Pod

    # Patch the podfile to let podfile only contain prebuild pods
    # class Podfile
    #
    #     class << self
    #
    #         patch_method :from_ruby do |old_method, args|
    #             podfile = old_method.(*args)
    #             p podfile.root_target_definitions
    #             podfile
    #         end
    #
    #     end
    #
    # end
    # class Installer
    #
    #     patch_method_before :install! do |*args|
    #         # manipulate the podfile, filter the binary pod
    #         if
    #         p podfile.root_target_definitions
    #     end
    # end

    class Prebuild

        # @param [Podfile] podfile
        def self.filter_podfile_content_for_prebuild_stage(podfile)

            target_definitions = podfile.target_definition_list

            all_explicit_pod_names = Set.new(target_definitions.map do |td|
                td.prebuild_framework_pod_names(inherent_parent: false)
            end.flatten)


            target_definitions.each do |target_definition|
                # pod dependency
                values = target_definition.send(:get_hash_value, 'dependencies')
                next if values.nil?
                values = values.select do |v|
                    pod = nil
                    if v.kind_of?(Hash)
                        pod = v.keys.first
                    elsif v.kind_of?(String)
                        pod = v
                    else
                        raise "unexpect type: #{v.inspect}"
                    end

                    root_pod = Specification.root_name(pod)
                    all_explicit_pod_names.include?(root_pod)
                end
                # modify the data directly
                target_definition.send(:set_hash_value, 'dependencies', values)


                # podspec dependency
                # podspec_dependencies
            end

        end



        private def walk_the_tree(targets_definitions, &action)
            return if targets_definitions.nil?
            targets_definitions.each do |t|
                action.call(t)
                walk_the_tree(t.children, &action)
            end
        end


    end

end