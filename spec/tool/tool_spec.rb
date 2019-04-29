require 'rspec'

RSpec.configure do |config|
    config.expect_with :rspec do |c|
        c.syntax = [:should, :expect]
    end
end
