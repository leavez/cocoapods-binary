require_relative 'prebuild_action'

module Pod
    def self.old_manifest_lock_file
        @@old_manifest_lock_file
    end
    def self.set_old_manifest_lock_file(value)
        @@old_manifest_lock_file = value
    end

    class Prebuild
        def self.framework_changes
            @@framework_changes
        end
        def self.set_framework_changes(value)
            @@framework_changes = value
        end
    end
end

Pod::HooksManager.register('cocoapods-prebuild-framework', :pre_install) do |installer_context|
    podfile = installer_context.podfile
    # check user_framework is on
    # podfile.use_frameworks!

    # Save manifest before generate a new one
    # it will be used in pod install hook (the code below)
    Pod.set_old_manifest_lock_file( installer_context.sandbox.manifest )
end

# patch prebuild ability
module Pod
    class Installer

        def prebuild_frameworks 

            sandbox_path = sandbox.root
            local_manifest = Pod.old_manifest_lock_file
            existed_framework_folder = Pod::Prebuild::Path.generated_frameworks_destination(sandbox_path)

            if local_manifest != nil

                changes = local_manifest.detect_changes_with_podfile(podfile)
                Pod::Prebuild.set_framework_changes(changes) # save the chagnes info for later stage
                added = changes[:added] || []
                changed = changes[:changed] || []
                unchanged = changes[:unchanged] || []
                deleted = changes[:removed] || []
    
                existed_framework_folder.mkdir unless existed_framework_folder.exist?
                exsited_framework_names = existed_framework_folder.children.map do |framework_name|
                    File.basename(framework_name, File.extname(framework_name))
                end

                # deletions
                # remove all frameworks except ones to remain
                unchange_framework_names = added + unchanged
                to_delete = exsited_framework_names.select do |framework_name|
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
                Pod::Prebuild.build(sandbox_path, self.pod_targets)
            end

            # Remove useless files
            # only keep manifest.lock and framework folder
            to_remain_files = ["Manifest.lock", File.basename(existed_framework_folder)]
            to_delete_files = sandbox_path.children.select do |file|
                filename = File.basename(file)
                not to_remain_files.include?(filename)
            end
            to_delete_files.each do |path|
                path.rmtree if path.exist?
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