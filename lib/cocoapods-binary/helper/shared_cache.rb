require 'aws-sdk-s3'
require 'digest'
require_relative '../tool/tool'
require 'zip'

module Pod
    class Prebuild
        class SharedCache
            extend Config::Mixin

            # `true` if there is cache for the target
            # `false` otherwise
            #
            # @return [Boolean]
            def self.has?(target, options)
                if Podfile::DSL.shared_cache_enabled
                    path = framework_cache_path_for(target, options, true)
                    result = path.exist?
                    if not result and Podfile::DSL.shared_s3_cache_enabled
                        s3_cache_path = framework_cache_path_for(target, options, false)
                        s3_cache_path = Podfile::DSL.s3_options[:prefix] + s3_cache_path  unless Podfile::DSL.s3_options[:prefix].nil?
                        s3 = Aws::S3::Resource.new(create_s3_options)
                        if s3.bucket(Podfile::DSL.s3_options[:bucket]).object("#{s3_cache_path}").exists?
                            Dir.mktmpdir {|dir|
                                s3.bucket(Podfile::DSL.s3_options[:bucket]).object("#{s3_cache_path}").get(response_target: "#{dir}/framework.zip")
                                unzip("#{dir}/framework.zip", path)
                                return true
                            }
                        end
                    end
                    result
                else
                    false
                end
            end

            # @return [{}] AWS connection options
            def self.create_s3_options
                options = {}
                creds = Aws::Credentials.new(Podfile::DSL.s3_options[:login], Podfile::DSL.s3_options[:password]) unless Podfile::DSL.s3_options[:login].nil? and Podfile::DSL.s3_options[:password].nil?
                options[:credentials] = creds unless creds.nil?
                options[:region] = Podfile::DSL.s3_options[:region] unless Podfile::DSL.s3_options[:region].nil?
                options[:endpoint] = Podfile::DSL.s3_options[:endpoint] unless Podfile::DSL.s3_options[:endpoint].nil?

                options
            end

            def self.zip(dir, zip_dir)
                Zip::File.open(zip_dir, Zip::File::CREATE)do |zipfile|
                    Find.find(dir) do |path|
                        Find.prune if File.basename(path)[0] == ?.
                        dest = /#{dir}\/(\w.*)/.match(path)
                        # Skip files if they exists
                        begin
                            zipfile.add(dest[1],path) if dest
                        rescue Zip::ZipEntryExistsError
                        end
                    end
                end
            end

            def self.unzip(zip, unzip_dir, remove_after = false)
                Zip::File.open(zip) do |zip_file|
                    zip_file.each do |f|
                        f_path=File.join(unzip_dir, f.name)
                        FileUtils.mkdir_p(File.dirname(f_path))
                        zip_file.extract(f, f_path) unless File.exist?(f_path)
                    end
                end
                FileUtils.rm(zip) if remove_after
            end

            # Copies input_path to target's cache and save to s3 if applicable
            def self.cache(target, input_path, options)
                if not Podfile::DSL.shared_cache_enabled
                    return
                end
                cache_path = framework_cache_path_for(target, options, true)
                cache_path.mkpath unless cache_path.exist?
                FileUtils.cp_r "#{input_path}/.", cache_path
                if Podfile::DSL.shared_s3_cache_enabled
                    s3_cache_path = framework_cache_path_for(target, options, false)
                    s3 = Aws::S3::Resource.new(create_s3_options)
                    Dir.mktmpdir {|dir|
                        zip(cache_path, "#{dir}/framework.zip")
                        s3.bucket(Podfile::DSL.s3_options[:bucket]).object("#{Podfile::DSL.s3_options[:prefix]}/#{s3_cache_path}").upload_file("#{dir}/framework.zip")
                    }
                end
            end

            # Path of the target's cache
            #
            # @return [Pathname]
            def self.framework_cache_path_for(target, options)
                framework_cache_path = Pathname.new('')
                if include_cache_root
                    framework_cache_path = cache_root
                end
                framework_cache_path = framework_cache_path + xcode_version
                framework_cache_path = framework_cache_path + target.name
                framework_cache_path = framework_cache_path + target.version
                options_with_platform = options + [target.platform.name]
                framework_cache_path = framework_cache_path + Digest::MD5.hexdigest(options_with_platform.to_s).to_s
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
            self.cache_root = config.cache_root + 'Prebuilt'
        end
    end
end