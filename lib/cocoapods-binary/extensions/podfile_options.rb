module Pod

    class Prebuild
        def self.keyword
            :binary
        end
    end

    class Podfile
      class TargetDefinition

        ## --- option for setting using prebuild framework ---
        def parse_prebuild_framework(name, requirements)

            options = requirements.last
            return requirements unless options.is_a?(Hash)

            pod_name = Specification.root_name(name)
            should_prebuild = options.delete(Prebuild.keyword)
            raise Informative, "pod '#{name}', :binary => #{should_prebuild}, should be Bool" unless [true, false, nil].include?(should_prebuild)

            if should_prebuild != nil
                set_prebuild_for_pod(pod_name, should_prebuild)
            else
                if Pod::Podfile::DSL.prebuild_all
                    set_prebuild_for_pod(pod_name, true)
                else
                    # do nothing
                end
            end

            requirements.pop if options.empty?
        end
        
        def set_prebuild_for_pod(pod_name, should_prebuild)

            if should_prebuild == true
                @prebuild_framework_pod_names ||= []
                @prebuild_framework_pod_names.push pod_name
            else
                @should_not_prebuild_framework_pod_names ||= []
                @should_not_prebuild_framework_pod_names.push pod_name
            end
        end

        def prebuild_framework_pod_names(inherent_parent: true)
            names = @prebuild_framework_pod_names || []
            if inherent_parent && parent != nil and parent.kind_of? TargetDefinition
                names += parent.prebuild_framework_pod_names
            end
            names
        end
        def should_not_prebuild_framework_pod_names(inherent_parent: true)
            names = @should_not_prebuild_framework_pod_names || []
            if inherent_parent && parent != nil and parent.kind_of?(TargetDefinition)
                names += parent.should_not_prebuild_framework_pod_names
            end
            names
        end

        # ---- patch method ----
        # We want modify `store_pod` method, but it's hard to insert a line in the 
        # implementation. So we patch a method called in `store_pod`.
        old_method = instance_method(:parse_inhibit_warnings)

        define_method(:parse_inhibit_warnings) do |name, requirements|
          parse_prebuild_framework(name, requirements)
          old_method.bind(self).(name, requirements)
        end
        
      end
    end



    class Podfile

        public

        # The pod names that set to binary explicitly in podfile
        #
        # if `all_binary!` is on, a pod without explicit binary flag will also be included.
        # A implicit dependency of a binary pod is not in this.
        #
        # @return [Set<String>]
        def explicitly_prebuild_pod_names
            @explicitly_prebuild_pod_names ||= begin
                target_definitions = self.target_definition_list

                all_explicit_pod_names = target_definitions.map do |td|
                    td.prebuild_framework_pod_names(inherent_parent: false)
                end.flatten

                Set.new(all_explicit_pod_names)
            end
        end

        # The pod names that set to not binary in podfile explicitly, i.e. pods with
        # `:binary => false`
        #
        # @return [Set<String>]
        def explicitly_not_prebuild_pod_names
            @explicitly_not_prebuild_pod_names = begin
                names = self.target_definition_list.map do |td|
                    td.should_not_prebuild_framework_pod_names(inherent_parent: false)
                end.flatten
                Set.new(names)
            end
        end

    end
end


