require_relative '../tool/tool'

module Pod
    class Prebuild
        class SharedCache
            # Keeps current xcode version.
            # Converts from "Xcode 10.2.1\nBuild version 10E1001\n" to "10.2.1".
            #
            # @return [String]
        # private
            class_attr_accessor :xcode_version
            self.xcode_version = `xcodebuild -version`.split("\n").first.split().last || "Unkwown"
        end
    end
  end