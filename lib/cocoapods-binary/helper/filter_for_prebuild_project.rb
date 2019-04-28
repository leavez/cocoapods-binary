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

            # get all prebuild_names
            # all_prebuild_names = []
            # walk_the_tree(podfile.target_definitions) do |definition|
            #     all_prebuild_names += definition.prebuild_framework_names(inherent_parent: false)
            # end
            # all_prebuild_names.uniq!
            #
            #
            # p podfile.root_target_definitions[0]
            # p podfile.root_target_definitions[0].children
            # definitions = podfile.root_target_definitions
            # p definitions[0].children[0].prebuild_framework_names
            # p definitions[0].children[0].should_not_prebuild_framework_names
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