
module Pod
  class Prebuild

    # Check the targets, for the current limitation of the plugin
    #
    # @param [Array<PodTarget>] prebuilt_targets
    def self.check_one_pod_should_have_only_one_target(prebuilt_targets)

      targets_have_different_platforms = prebuilt_targets.select {|t| t.pod_name != t.name }

      if targets_have_different_platforms.count > 0
        names = targets_have_different_platforms.map(&:pod_name)
        raw_names = targets_have_different_platforms.map(&:name)
        message = "Oops, you came across a limitation of cocoapods-binary.

The plugin requires that one pod should have ONLY ONE target in the 'Pod.xcodeproj'. There are mainly 2 situations \
causing this problem:

1. One pod integrates in 2 or more different platforms' targets. e.g.
    ```
    target 'iphoneApp' do
      pod 'A', :binary => true
    end
    target 'watchApp' do
      pod 'A'
    end
    ```

2. Use different subspecs in multiple targets. e.g.
    ```
    target 'iphoneApp' do
      pod 'A/core'
      pod 'A/network'
    end
    target 'iphoneAppTest' do
      pod 'A/core'
    end
    ```

Related pods: #{names}, target names: #{raw_names}
        "
        raise Informative, message
      end
    end


  end
end