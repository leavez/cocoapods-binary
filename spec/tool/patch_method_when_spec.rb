require 'rspec'
require 'cocoapods-binary/tool/patch_method_when'

describe 'Patch method when' do

    it 'should patch the content' do
        module SpecPatchMethodWhen
            class A
                def m
                    "1"
                end

                modify_method('m', only_when: Proc.new{ true }) do |old_method, args|
                    "2"
                end
            end

            ins = A.new
            ins.m().should == '2'
        end
    end

    it "the condition switch should be valid " do
        module SpecPatchMethodWhen
            class Switch
                class << self
                    attr_accessor :on
                end
            end
            class G
                def m
                    "1"
                end

                modify_method('m', only_when: Proc.new{ Switch.on }) do |old_method, args|
                    "2"
                end
            end

            ins = G.new
            Switch.on = true
            ins.m().should == '2'
            Switch.on = false
            ins.m().should == '1'
        end

    end


    it 'should keep the args' do
        module SpecPatchMethodWhen
            class B
                def m(a, b)
                    "1#{a}#{b}"
                end

                modify_method('m', only_when: Proc.new{ true }) do |old_method, args|
                    "2#{args[0]}#{args[1]}"
                end
            end

            ins = B.new
            ins.m(1,2).should == '212'
        end
    end

    it "should have right scope" do
        module SpecPatchMethodWhen
            class C
                def m
                end

                def who_am_i
                    self.class.name
                end

                modify_method('m', only_when: Proc.new{ true }) do |old_method, args|
                    who_am_i
                end
            end

            C.new.m.should == 'SpecPatchMethodWhen::C'
        end
    end

    it "the original method is can be accessed" do
        module SpecPatchMethodWhen
            class D
                def m(a)
                    "1#{a}"
                end

                modify_method('m', only_when: Proc.new{ true }) do |old_method, args|
                    old_method.(*args)
                end
            end

            D.new.m(2).should == '12'
        end
    end


end


