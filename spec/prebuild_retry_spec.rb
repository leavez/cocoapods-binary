require 'spec_helper'
require 'cocoapods-binary/Prebuild'


module Pod


    describe 'Prebuild' do
        describe 'Install' do
            describe 'Retry Mechanism' do

                before(:each) do
                    SpecHelper.prebuild_installer_stubs(self)
                end

                context 'when explicitly set requirements for dependencies and make it non-binary' do
                    before(:each) do
                        SpecHelper.stub_pod_dependencies(self, {
                            RxCocoa: [['RxSwift', '>=4.4.0']],
                            RxSwift: ['RxAtomic', '4.4.0'],
                        })
                        @installer, @sandbox, @podfile =  Pod.build_installer do
                            target 'A' do
                                pod "RxCocoa", '4.4.0', :binary => true
                                pod "RxSwift", '4.5.0', :binary => false
                                pod "SnapKit"
                            end
                        end
                    end

                    it "should retry" do
                        expect(@installer).to receive(:regenerate_installer).exactly(:once).and_call_original
                        @installer.install!
                    end

                    it "should give "
                end


            end
        end
    end
end
