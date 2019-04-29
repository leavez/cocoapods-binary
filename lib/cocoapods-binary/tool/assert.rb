class AssertError < StandardError
end


def assert(condition, message="")
    raise AssertError, message unless condition
end

def assert_type(variable, type_class)
    assert(variable.kind_of?(type_class), "Type is incorrect: #{variable.class} is not #{type_class}")
end

def assert_type_array_of(variable, type_class)
    assert type_class != nil,'Input type is nil'
    assert_type variable, Array
    if variable.first
        assert_type variable.first, type_class
    end
end