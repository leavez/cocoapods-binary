# attr_accessor for class variable.
# usage:
#
#   ```
#   class Pod
#       class_attr_accessor :is_prebuild_stage
#   end
#   ```
#
def class_attr_accessor(symbol)
    self.class.send(:attr_accessor, symbol)
end