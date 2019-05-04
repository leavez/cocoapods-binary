require_relative 'patch_method'
require_relative 'assert'


# Only execute the patched content when condition returns true,
# otherwise execute the original method.
#
# @param [Proc return bool] only_when: the condition
# @see patch_method
def modify_method(method_name, only_when:, &content)
    condition = only_when
    assert_type condition, Proc
    patch_method(method_name) do |old_method, args|
        if condition.call
            instance_exec old_method, args, &content
        else
            old_method.(*args)
        end
    end
end

# @see patch_method_after
def do_after_method(method_name, only_when:, &content)
    condition = only_when
    assert_type condition, Proc
    patch_method(method_name) do |old_method, args|
        if condition.call
            old_result = old_method.(*args)
            instance_exec *args, &content
            next old_result
        else
            old_method.(*args)
        end
    end
end

# @see patch_method_before
def do_before_method(method_name, only_when:, &content)
    condition = only_when
    assert_type condition, Proc
    patch_method(method_name) do |old_method, args|
        if condition.call
            instance_exec *args, &content
            old_method.(*args)
        else
            old_method.(*args)
        end
    end
end
