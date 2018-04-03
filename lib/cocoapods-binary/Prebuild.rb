require_relative 'rome/build_framework'

module Pod    
    class Prebuild
        class_attr_accessor :framework_changes
    end
end


# patch prebuild ability
module Pod
    class Installer

        def local_manifest 
            if not @local_manifest_inited
                @local_manifest_inited = true
                raise "This method should be call before generate project" unless self.analysis_result == nil
                @local_manifest = self.sandbox.manifest
            end
            @local_manifest
        end

        
        # check if need to prebuild
        def have_exact_prebuild_cache?
            # check if need build frameworks
            return false if local_manifest == nil
            
            changes = local_manifest.detect_changes_with_podfile(podfile)
            changes = Analyzer::SpecsState.new(changes)
            Pod::Prebuild.framework_changes = changes # save the chagnes info for later stage
            added = changes.added
            changed = changes.changed 
            unchanged = changes.unchanged
            deleted = changes.deleted 
            
            unchange_framework_names = (added + unchanged)

            exsited_framework_names = sandbox.exsited_framework_names
            missing = unchanged.select do |pod_name|
                not exsited_framework_names.include?(pod_name)
            end

            needed = (added + changed + deleted + missing)
            return needed.empty?
        end
        
        
        # The install method when have completed cache
        def install_when_cache_hit!
            # just print log
            self.sandbox.exsited_framework_names.each do |name|
                UI.puts "Using #{name}"
            end
        end
    

        # Build the needed framework files
        def prebuild_frameworks 

            local_manifest = self.local_manifest
            sandbox_path = sandbox.root
            existed_framework_folder = sandbox.generate_framework_path
            bitcode_enabled = Pod::Podfile::DSL.is_bitcode_enabled

            targets = []
            if local_manifest != nil

                changes = local_manifest.detect_changes_with_podfile(podfile)
                changes = Analyzer::SpecsState.new(changes)
                added = changes.added
                changed = changes.changed 
                unchanged = changes.unchanged
                deleted = changes.deleted 
    
                existed_framework_folder.mkdir unless existed_framework_folder.exist?
                exsited_framework_names = sandbox.exsited_framework_names
                
                # deletions
                # remove all frameworks except ones to remain
                unchange_framework_names = (added + unchanged)
                to_delete = exsited_framework_names.select do |framework_name|
                    not unchange_framework_names.include?(framework_name)
                end
                to_delete.each do |framework_name|
                    path = sandbox.framework_folder_path_for_pod_name(framework_name)
                    path.rmtree if path.exist?
                end
    
                # additions
                missing = unchanged.select do |pod_name|
                    not exsited_framework_names.include?(pod_name)
                end


                
                root_names_to_update = (added + changed + missing)

                name_to_target_hash = self.pod_targets.reduce({}) do |sum, target|
                    sum[target.name] = target
                    sum
                end

                targets = root_names_to_update.map do |root_name|
                    name_to_target_hash[root_name]
                end
            else
                targets = self.pod_targets
            end
            
            # build!
            Pod::UI.puts "Prebuild frameworks (total #{targets.count})"
            Pod::Prebuild.remove_build_dir(sandbox_path)
            targets.each do |target|
                next unless target.should_build?
                output_path = sandbox.framework_folder_path_for_pod_name(target.name)
                output_path.mkpath unless output_path.exist?
                Pod::Prebuild.build(sandbox_path, target, output_path, bitcode_enabled)
            end            
            Pod::Prebuild.remove_build_dir(sandbox_path)


            # copy vendored libraries and frameworks
            targets.each do |target|
                root_path = self.sandbox.pod_dir(target.name)
                target.spec_consumers.each do |consumer|
                    file_accessor = Sandbox::FileAccessor.new(root_path, consumer)
                    lib_paths = file_accessor.vendored_frameworks || []
                    lib_paths += file_accessor.vendored_libraries
                    # @TODO dSYM files
                    lib_paths.each do |lib_path|
                        relative = lib_path.relative_path_from(root_path)
                        destination = sandbox.framework_folder_path_for_pod_name(target.name) + relative
                        destination.dirname.mkpath unless destination.dirname.exist?
                        FileUtils.cp_r(lib_path, destination, :remove_destination => true)
                    end
                end
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