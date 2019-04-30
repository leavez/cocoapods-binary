require 'rspec'
require 'cocoapods-binary/tool/patch_method'



describe 'Patch method' do

    it 'should patch the content' do
        module SpecPatchMethod
            class A
                def m
                    "1"
                end

                patch_method('m') do |old_method, args|
                    "2"
                end
            end

            ins = A.new
            ins.m().should == '2'
        end
    end

    it 'should keep the args' do
        module SpecPatchMethod
            class B
                def m(a, b)
                    "1#{a}#{b}"
                end

                patch_method('m') do |old_method, args|
                    "2#{args[0]}#{args[1]}"
                end
            end

            ins = B.new
            ins.m(1,2).should == '212'
        end
    end

    it "should have right scope" do
        module SpecPatchMethod
            class C
                def m
                end

                def who_am_i
                    self.class.name
                end

                patch_method('m') do |old_method, args|
                    who_am_i
                end
            end

            C.new.m.should == 'SpecPatchMethod::C'
        end
    end

    it "the original method is can be accessed" do
        module SpecPatchMethod
            class D
                def m(a)
                    "1#{a}"
                end

                patch_method('m') do |old_method, args|
                    old_method.(*args)
                end
            end

            D.new.m(2).should == '12'
        end
    end

    it "can call multiple times" do
        module SpecPatchMethod
            class E
                def m(a)
                    "0#{a}"
                end

                patch_method('m') do |old_method, args|
                    old_method.(*args) + "2"
                end
                patch_method('m') do |old_method, args|
                    old_method.(*args) + "3"
                end
            end

            E.new.m(1).should == '0123'
        end
    end

    it "can keep original default value" do
        module SpecPatchMethod
            class F
                def m(a='D')
                    "0#{a}"
                end

                patch_method('m') do |old_method, args|
                    old_method.(*args) + "2"
                end
                patch_method('m') do |old_method, args|
                    old_method.(*args) + "3"
                end
            end

            F.new.m().should == '0D23'
            F.new.m(1).should == '0123'
        end
    end

end



describe 'Patch method before' do

    it 'should patch the content' do
        module SpecPatchMethodBefore
            class A
                attr_accessor :output
                def m
                    output << 1
                end

                patch_method_before('m') do |*args|
                    self.output = [2]
                end

            end

            a = A.new
            a.m().should == [2, 1]
        end
    end

    it 'should keep the args' do
        module SpecPatchMethodBefore
            class B
                attr_accessor :output
                def m(a,b)
                    self.output ||= []
                    output << a
                    output << b
                end

                patch_method_before('m') do |*args|
                    self.output ||= []
                    self.output += args
                end
            end
            a = B.new
            a.m(1,2)
            a.output.should == [1,2,1,2]
        end
    end

    it "should have right scope" do
        module SpecPatchMethodBefore
            class C
                attr_accessor :output
                def m
                end

                def do_it
                    self.output = 1
                end

                patch_method_before('m') do
                    do_it
                end
            end

            a = C.new
            a.m
            a.output.should == 1
        end
    end

    it "won't affect the original result" do
        module SpecPatchMethodBefore
            class D
                def m(a)
                    "1#{a}"
                end

                patch_method_before('m') do |*args|
                    nil
                end
            end

            D.new.m(2).should == '12'
        end
    end

end





describe 'Patch method after' do

    it 'should patch the content' do
        module SpecPatchMethodAfter
            class A
                attr_accessor :output
                def m
                    self.output = [2]
                end

                patch_method_after('m') do |*args|
                    output << 1
                end

            end

            a = A.new
            a.m().should == [2, 1]
        end
    end

    it 'should keep the args' do
        module SpecPatchMethodAfter
            class B
                attr_accessor :output
                def m(a,b)
                    self.output ||= []
                    output << a
                    output << b
                end

                patch_method_after('m') do |*args|
                    self.output ||= []
                    self.output += args
                end
            end

            a = B.new
            a.m(1,2)
            a.output.should == [1,2,1,2]
        end
    end

    it "should have right scope" do
        module SpecPatchMethodAfter
            class C
                attr_accessor :output
                def m
                end

                def do_it
                    self.output = 1
                end

                patch_method_after('m') do
                    do_it
                end
            end

            a = C.new
            a.m
            a.output.should == 1
        end
    end

    it "won't affect the original result" do
        module SpecPatchMethodAfter
            class D
                def m(a)
                    "1#{a}"
                end

                patch_method_after('m') do |*args|
                    nil
                end
            end

            D.new.m(2).should == '12'
        end
    end

end