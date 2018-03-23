require_relative 'podfile_options'
require_relative 'feature_switches'
require_relative 'path'

# Provide a special "download" process for prebuilded pods.
#
# As the frameworks is already exsited in local folder. We
# just create a symlink to the original target folder.
#
module Pod
    class Installer
        class PodSourceInstaller

            def install_for_prebuild!(standard_sanbox)
                # make a symlink to target folder
                prebuild_sanbox_path = Pod::Prebuild::Path.prebuild_sanbox_path(standard_sanbox.root)
                frameworks_path = Pod::Prebuild::Path.generated_frameworks_destination(prebuild_sanbox_path)
                source = frameworks_path + "#{self.name}.framework"
                target_folder = standard_sanbox.pod_dir(self.name)
                target_folder.mkdir unless target_folder.exist?
                target = target_folder + "#{self.name}.framework"
                File.symlink(source, target)
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


        # Modify specification to use only the prebuild framework after analyzing
        old_method2 = instance_method(:resolve_dependencies)
        define_method(:resolve_dependencies) do
            old_method2.bind(self).()
            return if Pod.is_prebuild_stage

            self.analysis_result.specifications.each do |spec|
                next unless self.prebuild_pod_names.include? spec.name
                spec.attributes_hash["vendored_frameworks"] = "#{spec.name}.framework"
                spec.attributes_hash["source_files"] = []
            end
        end


        # Override the download step to skip download and prepare file in target folder
        old_method = instance_method(:install_source_of_pod)
        define_method(:install_source_of_pod) do |pod_name|

            if Pod.is_prebuild_stage
                return old_method.bind(self).(pod_name)
            end

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

