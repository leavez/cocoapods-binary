require_relative 'rome/build_framework'

module Pod    
    class Prebuild
        class_attr_accessor :framework_changes
    end
end

Pod::HooksManager.register('cocoapods-binary', :pre_install) do |installer_context|
    
    # check user_framework is on
    podfile = installer_context.podfile
    podfile.target_definition_list.each do |target_definition|
        next if target_definition.prebuild_framework_names.empty?
        if not target_definition.uses_frameworks?
            STDERR.puts "[!] Cocoapods-binary requires `use_frameworks!`".red
            exit
        end
    end
end

# patch prebuild ability
module Pod

    class_attr_accessor :old_manifest_lock_file

    class Installer
        
        def prebuild_frameworks 

            local_manifest = Pod.old_manifest_lock_file
            sandbox_path = sandbox.root
            existed_framework_folder = sandbox.generate_framework_path

            if local_manifest != nil

                changes = local_manifest.detect_changes_with_podfile(podfile)
                Pod::Prebuild.framework_changes = changes # save the chagnes info for later stage
                added = changes[:added] || []
                changed = changes[:changed] || []
                unchanged = changes[:unchanged] || []
                deleted = changes[:removed] || []
    
                existed_framework_folder.mkdir unless existed_framework_folder.exist?
                exsited_framework_names = sandbox.exsited_framework_names
                
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
                Pod::Prebuild.build(sandbox_path, existed_framework_folder, targets)
                
            else
                Pod::Prebuild.framework_changes = nil
                Pod::Prebuild.build(sandbox_path, existed_framework_folder, self.pod_targets)
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

        # check if need to prebuild
        old_method = instance_method(:install!)
        define_method(:install!) do
            return old_method.bind(self).() unless Pod.is_prebuild_stage

            # check if need build frameworks
            local_manifest = self.sandbox.manifest
            changes = local_manifest.detect_changes_with_podfile(podfile)
            added = changes[:added] || []
            changed = changes[:changed] || []
            unchanged = changes[:unchanged] || []

            unchange_framework_names = added + unchanged
            exsited_framework_names = sandbox.exsited_framework_names
            missing = unchanged.select do |pod_name|
                not exsited_framework_names.include?(pod_name)
            end

            if (added + changed + missing).empty? 
                # don't do the install
                exsited_framework_names.each do |name|
                    UI.puts "Using #{name}"
                end
                return
            end
            
            # normal install
            # Save manifest before generate a new one
            Pod.old_manifest_lock_file = local_manifest
            old_method.bind(self).()
        end
        
        # patch the post install hook
        old_method2 = instance_method(:run_plugins_post_install_hooks)
        define_method(:run_plugins_post_install_hooks) do 
            old_method2.bind(self).()
            if Pod::is_prebuild_stage
                self.prebuild_frameworks
            end
        end


    end
end