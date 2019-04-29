require_relative 'patch_method'
require_relative 'assert'

# Only execute the patched content when condition is true,
# otherwise execute the original method.
#
# @param [Proc return bool] condition
# @see patch_method
def patch_method_when(method_name, condition, &content)
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
def patch_method_after_when(method_name, condition, &content)
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
def patch_method_before_when(method_name, condition, &content)
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