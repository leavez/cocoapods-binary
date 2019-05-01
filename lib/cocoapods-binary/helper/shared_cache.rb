require_relative '../tool/tool'

module Pod
    class Prebuild
        class SharedCache
            extend Config::Mixin

            # `true` if there is cache for the target
            # `false` otherwise
            #
            # @return [Boolean]
            def self.has?(target)
                if Podfile::DSL.shared_cache_enabled
                    framework_cache_path_for(target).exist?
                else
                    false
                end
            end

            # Copies input_path to target's cache
            def self.cache(target, input_path)
                if not Podfile::DSL.shared_cache_enabled
                    return
                end
                cache_path = framework_cache_path_for(target)
                cache_path.mkpath unless cache_path.exist?
                FileUtils.cp_r "#{input_path}/.", cache_path
            end

            # Path of the target's cache
            #
            # @return [Pathname]
            def self.framework_cache_path_for(target)
                framework_cache_path = cache_root + xcode_version
                framework_cache_path = framework_cache_path + target.name
                framework_cache_path = framework_cache_path + target.version
            end

            # Current xcode version.
            #
            # @return [String]
            private
            class_attr_accessor :xcode_version
            # Converts from "Xcode 10.2.1\nBuild version 10E1001\n" to "10.2.1".
            self.xcode_version = `xcodebuild -version`.split("\n").first.split().last || "Unkwown"

            # Path of the cache folder
            # Reusing cache_root from cocoapods's config
            # `~Library/Caches/CocoaPods` is default value
            #
            # @return [Pathname]
            private
            class_attr_accessor :cache_root
            self.cache_root = config.cache_root + 'Prebuild'
        end
    end
end