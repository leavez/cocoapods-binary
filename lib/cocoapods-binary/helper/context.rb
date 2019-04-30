require_relative '../tool/tool'

module Pod
    class Prebuild


        class Context
            class_attr_accessor :in_prebuild_stage
        end


        # Convenient method to return the condition proc object for patch.
        # It indicates whether we are in prebuild stage.
        # @return [Proc]
        def self.prebuild_stage_condition
            Proc.new do
                Context.in_prebuild_stage
            end
        end

        def self.integration_stage_condition
            Proc.new do
                !Context.in_prebuild_stage
            end
        end
    end
end