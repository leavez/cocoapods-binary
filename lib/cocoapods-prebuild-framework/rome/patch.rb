require_relative 'prebuild_action'

# check user_framework is on
Pod::HooksManager.register('cocoapods-prebuild-framework', :pre_install) do |installer_context|
    podfile = installer_context.podfile
    # podfile.use_frameworks!
end

# patch prebuild ability
module Pod
    class Installer

        def prebuild_frameworks 
            
            sandbox_path = sandbox.root
            local_manifest = self.sandbox.manifest

            if local_manifest != nil
                changes = local_manifest.detect_changes_with_podfile(podfile)
                added = changes[:added] || []
                changed = changes[:changed] || []
                unchanged = changes[:unchanged] || []
                deleted = changes[:removed] || []
    
                existed_framework_folder = Pod::Prebuild::Path.generated_frameworks_destination(Pathname(sandbox_path))
                exsited_framework_names = existed_framework_folder.children.map do |framework_name|
                    File.basename(framework_name, File.extname(framework_name))
                end

                # deletions
                # remove all frameworks except ones to remain
                unchange_framework_names = added + unchanged
                to_delete = exsited_framework_names.each do |framework_name|
                    not unchange_framework_names.include?(framework_name)
                end
                to_delete.each do |framework_name|
                    path = existed_framework_folder + (framework_name + ".framework")
                    path.rmtree if path.exist?
                end
    
                # additions
                missing = unchanged.select do |pod_name|
                    not exsited_framework_names.include?(pod_name)
                end

                targets = (added + changed + missing).map do |pod_name|
                    self.pod_targets.find do |pod_target|
                        pod_target.root_spec.name == pod_name
                    end
                end
                Pod::Prebuild.build(sandbox_path, targets)
                
            else
                puts "B"
                Pod::Prebuild.build(sandbox_path, self.pod_targets)
            end

        end


        # path the post install hook
        old_method = instance_method(:run_plugins_post_install_hooks)
        define_method(:run_plugins_post_install_hooks) do 
            old_method.bind(self).()
            if Pod::Prebuild.prebuild_enabled
                self.prebuild_frameworks
            end
        end

    end
end