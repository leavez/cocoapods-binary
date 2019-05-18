require 'pathname'
require 'cocoapods'
require 'cocoapods_plugin'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
  config.mock_with :rspec do |mocks|
    mocks.syntax = [:expect, :should]
  end
end

#-----------------------------------------------------------------------------#

module Pod

  # Disable the wrapping so the output is deterministic in the tests.
  #
  UI.disable_wrap = true

  # Redirects the messages to an internal store.
  #
  module UI
    @output = ''
    @warnings = ''

    class << self
      attr_accessor :output
      attr_accessor :warnings

      def puts(message = '')
        @output << "#{message}\n"
      end

      def warn(message = '', actions = [])
        @warnings << "#{message}\n"
      end

      def print(message)
        @output << message
      end
    end
  end
end

#-----------------------------------------------------------------------------#
module Pod

    def self.build_installer(&podfile_text)
      # Config.instance.silent = true
      sandbox = Sandbox.new(Dir.tmpdir + "/binary_spec_#{Time.new.to_i}")
      block = Proc.new do
        platform :ios, '12.0'
        instance_eval &podfile_text
      end
      podfile = Podfile.new &block
      podfile.instance_eval do
          @initial_block =  block
      end
      installer = Installer.new(sandbox, podfile)
      installer.installation_options.integrate_targets = false
      [installer, sandbox, podfile]
    end


  module SpecHelper

    # mock the methods for installer
    def self.prebuild_installer_stubs(context)
      context.instance_eval do
          allow_any_instance_of(Installer).to receive(:prebuild_frameworks!) {   }
          [:download_dependencies, :validate_targets, :generate_pods_project, :perform_post_install_actions].each do |method|
            allow_any_instance_of(Installer).to receive(method) {  }
          end
          Prebuild::Context.stub(:in_prebuild_stage).and_return(true)

          allow_any_instance_of(Installer).to receive(:regenerate_original_podfile) { |s|
            block = s.podfile.instance_variable_get(:@initial_block) # set in the #build_installer method
            assert block != nil
            podfile = Podfile.new(&block)
            podfile.instance_variable_set(:@initial_block, block)
            podfile
          }
      end
    end

    # mock the dependency of pods, as the dependency may changed along pod version
    # @param [Hash<Symbol, Array<Arrary<String>>>] modification
    def self.stub_pod_dependencies(context, modification)
      raise if modification.nil?
      if !@specification_hooked
        Specification.class_eval do
          alias_method :original_dependencies, :dependencies
        end
        @specification_hooked = true
      end

      context.instance_eval do
          allow_any_instance_of(Specification).to receive(:dependencies) { |s|
            deps = modification[s.name.to_sym] || modification[s.name.to_s]
            if deps
              if deps == []
                next []
              end
              if deps.first.kind_of? String
                deps = [deps]
              end
              next deps.map{ |name_and_version| Dependency.new(name_and_version[0].to_s, name_and_version[1]) }
            end
            if modification[:keep_untouched]
              next s.original_dependencies
            else
              []
            end
          }
      end

    end


  end
end

