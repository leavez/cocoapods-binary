require_relative 'helper/podfile_options'
require_relative 'helper/feature_switches'
require_relative 'helper/prebuild_sandbox'
require_relative 'helper/passer'
require_relative 'helper/names'



# NOTE:
# This file will only be loaded on normal pod install step
# so there's no need to check is_prebuild_stage



# Provide a special "download" process for prebuilded pods.
#
# As the frameworks is already exsited in local folder. We
# just create a symlink to the original target folder.
#
module Pod
    class Installer
        class PodSourceInstaller

            def install_for_prebuild!(standard_sanbox)
                return if standard_sanbox.local? self.name

                # make a symlink to target folder
                prebuild_sandbox = Pod::PrebuildSandbox.from_standard_sandbox(standard_sanbox)
                # if spec used in multiple platforms, it may return multiple paths
                target_names = root_spec.prebuild_target_names_in_prebuild_sandbox(prebuild_sandbox)
                
                
                def walk(path, &action)
                    path.children.each do |child|
                        result = action.call(child, &action)
                        if child.directory?
                            walk(child, &action) if result
                        end
                    end
                end
                def make_link(source, target)
                    source = Pathname.new(source)
                    target = Pathname.new(target)
                    target.parent.mkpath unless target.parent.exist?
                    relative_source = source.relative_path_from(target.parent)
                    FileUtils.ln_sf(relative_source, target)
                end
                def mirror_with_symlink(source, basefolder, target_folder)
                    target = target_folder + source.relative_path_from(basefolder)
                    make_link(source, target)
                end
                
                target_names.each do |name|

                    # symbol link copy all substructure
                    real_file_folder = prebuild_sandbox.framework_folder_path_for_target_name(name)
                    
                    # If have only one platform, just place int the root folder of this pod.
                    # If have multiple paths, we use a sperated folder to store different
                    # platform frameworks. e.g. AFNetworking/AFNetworking-iOS/AFNetworking.framework
                    
                    target_folder = standard_sanbox.pod_dir(self.name)
                    if target_names.count > 1 
                        target_folder += real_file_folder.basename
                    end
                    target_folder.rmtree if target_folder.exist?
                    target_folder.mkpath


                    walk(real_file_folder) do |child|
                        source = child
                        # only make symlink to file and `.framework` folder
                        if child.directory? and child.extname == ".framework"
                            mirror_with_symlink(source, real_file_folder, target_folder)
                            next false  # return false means don't go deeper
                        elsif child.file?
                            mirror_with_symlink(source, real_file_folder, target_folder)
                            next true
                        else
                            next true
                        end
                    end


                    # symbol link copy resource for static framework
                    hash = Prebuild::Passer.resources_to_copy_for_static_framework || {}
                    
                    path_objects = hash[name]
                    if path_objects != nil
                        path_objects.each do |object|
                            make_link(object.real_file_path, object.target_file_path)
                        end
                    end
                end # of for each 

            end # of method

        end
    end
end


# Let cocoapods use the prebuild framework files in install process.
#
# the code only effect the second pod install process.
#
module Pod
    class Installer


        # Remove the old target files if prebuild frameworks changed
        def remove_target_files_if_needed

            changes = Pod::Prebuild::Passer.prebuild_pods_changes
            updated_names = []
            if changes == nil
                updated_names = PrebuildSandbox.from_standard_sandbox(self.sandbox).exsited_framework_names
            else
                added = changes.added
                changed = changes.changed 
                deleted = changes.deleted 
                updated_names = added + changed + deleted
            end

            updated_names.each do |name|
                root_name = Specification.root_name(name)
                next if self.sandbox.local?(root_name)

                # delete the cached files
                target_path = self.sandbox.pod_dir(root_name)
                target_path.rmtree if target_path.exist?

                support_path = sandbox.target_support_files_dir(root_name)
                support_path.rmtree if support_path.exist?
            end

        end


        # Modify specification to use only the prebuild framework after analyzing
        old_method2 = instance_method(:resolve_dependencies)
        define_method(:resolve_dependencies) do

            # Remove the old target files, else it will not notice file changes
            self.remove_target_files_if_needed

            # call original
            old_method2.bind(self).()


            # check the prebuilt targets 
            targets = self.prebuild_pod_targets
            targets_have_different_platforms = targets.select {|t| t.pod_name != t.name }

            if targets_have_different_platforms.count > 0
                names = targets_have_different_platforms.map(&:pod_name)
                STDERR.puts "[!] Binary doesn't support pods who integrate in 2 or more platforms simultaneously: #{names}".red
                exit
            end


            specs = self.analysis_result.specifications
            prebuilt_specs = (specs.select do |spec|
                self.prebuild_pod_names.include? spec.root.name
            end)
            
            # make sturcture to fast get target by name
            name_to_target_hash = self.pod_targets.reduce({}) do |sum, target|
                sum[target.name] = target
                sum
            end

            prebuilt_specs.each do |spec|
                # `spec` may be a subspec, so we use the root's name 
                root_name = spec.root.name
                
                target = name_to_target_hash[root_name]
                next if Prebuild::Passer.target_names_to_skip_integration_framework.include? target.pod_name

                # use the prebuilt framework
                original_vendored_frameworks = spec.attributes_hash["vendored_frameworks"] || []
                if original_vendored_frameworks.kind_of?(String)
                    original_vendored_frameworks = [original_vendored_frameworks]
                end
                original_vendored_frameworks += [target.framework_name]
                spec.attributes_hash["vendored_frameworks"] = original_vendored_frameworks
                spec.attributes_hash["source_files"] = []

                # to avoid the warning of missing license
                spec.attributes_hash["license"] = {} 
            end

        end


        # Override the download step to skip download and prepare file in target folder
        old_method = instance_method(:install_source_of_pod)
        define_method(:install_source_of_pod) do |pod_name|

            # copy from original
            pod_installer = create_pod_installer(pod_name)
            # \copy from original

            if self.prebuild_pod_names.include? pod_name
                pod_installer.install_for_prebuild!(self.sandbox)
            else
                pod_installer.install!
            end

            # copy from original
            @installed_specs.concat(pod_installer.specs_by_platform.values.flatten.uniq)
            # \copy from original
        end


    end
end

# A fix in embeded frameworks script.
#
# The framework file in pod target folder is a symblink. The EmbedFrameworksScript use `readlink`
# to read the read path. As the symlink is a relative symlink, readlink cannot handle it well. So 
# we override the `readlink` to a fixed version.
#
module Pod
    module Generator
        class EmbedFrameworksScript

            old_method = instance_method(:script)
            define_method(:script) do

                script = old_method.bind(self).()
                patch = <<-SH.strip_heredoc
                    #!/bin/sh
                
                    # ---- this is added by cocoapods-binary ---
                    # Readlink cannot handle relative symlink well, so we override it to a new one
                    # If the path isn't an absolute path, we add a realtive prefix.
                    readlink () {
                        path=`/usr/bin/readlink $1`;
                        if [ $(echo "$path" | cut -c 1-1) = '/' ]; then
                            echo $path;
                        else
                            echo "`dirname $1`/$path";
                        fi
                    }
                    # --- 
                SH
                patch + script
            end
        end
    end
end