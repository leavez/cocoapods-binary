require_relative 'podfile_options'
require_relative 'feature_switches'
require_relative 'prebuild_sandbox'

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
                folder = prebuild_sandbox.framework_folder_path_for_pod_name(self.name)

                target_folder = standard_sanbox.pod_dir(self.name)
                target_folder.rmtree if target_folder.exist?
                target_folder.mkdir

                # make a relatvie symbol link for all children
                folder.children.each do |child|
                    source = child
                    target = target_folder + File.basename(source)
                    
                    relative_source = source.relative_path_from(target.parent)
                    FileUtils.ln_sf(relative_source, target)
                end
            end

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

            changes = Pod::Prebuild.framework_changes
            updated_names = []
            if changes == nil
                updated_names = PrebuildSandbox.from_standard_sandbox(self.sandbox).exsited_framework_names
            else
                added = changes[:added] || []
                changed = changes[:changed] || []
                deleted = changes[:removed] || []
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
            old_method2.bind(self).()

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

                # use the prebuilt framework
                target = name_to_target_hash[root_name]
                spec.attributes_hash["vendored_frameworks"] = target.framework_name
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

