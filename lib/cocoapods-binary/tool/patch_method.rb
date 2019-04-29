

# Patch a method
# @param [Symbol] method_name
# @param [block] content, args: 1 old_method, 2 the array of original args
# ```
# patch_method :AAA do |old_method, args|
#   old_method.(*args) # execute the original method
# end
# ```
def patch_method(method_name, &content)
    return if content.nil?
    old = instance_method(method_name)
    raise "Found no method named: #{method_name}" if old.nil?

    define_method(method_name) do |*args|
        instance_exec old.bind(self), args, &content
    end
end

# It won't change the return value of the original method
# @param [Symbol] method_name
# @param [block] content, args: the original args
# ```
# patch_method_after :AAA do |*args|
#   # execute the original method
#   # the added actions
#   puts "after the original action"
#   # return the original result
# end
# ```
def patch_method_after(method_name, &content)
    return if content.nil?
    patch_method(method_name) do |old_method, args|
        old_result = old_method.(*args)
        instance_exec *args, &content
        next old_result
    end
end

# @param [Symbol] method_name
# @param [block] content, args: the original args
def patch_method_before(method_name, &content)
    return if content.nil?
    patch_method(method_name) do |old_method, args|
        instance_exec *args, &content
        next old_method.(*args)
    end
end