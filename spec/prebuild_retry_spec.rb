# require 'spec_helper'
# require 'cocoapods-binary/Prebuild'
#
#
# module Pod
#
#
#     describe 'Prebuild' do
#         describe 'Install' do
#             describe 'Retry Mechanism' do
#
#                 before(:each) do
#                     SpecHelper.prebuild_installer_stubs(self)
#                 end
#
#                 context 'when explicitly set requirements for dependencies and make it non-binary' do
#                     before(:each) do
#                         SpecHelper.stub_pod_dependencies(self, {
#                             RxCocoa: [['RxSwift', '>=4.4.0']],
#                             RxSwift: ['RxAtomic', '4.4.0'],
#                         })
#                         @installer, @sandbox, @podfile =  Pod.build_installer do
#                             target 'A' do
#                                 pod "RxCocoa", '4.4.0', :binary => true
#                                 pod "RxSwift", '4.5.0', :binary => false
#                                 pod "SnapKit"
#                             end
#                         end
#                     end
#
#                     it "should throw a error when analyze dependency" do
#                         class SpecError < StandardError; end
#                         expect(@installer).to receive(:resolve_dependencies).and_wrap_original { |m, *args|
#                             begin
#                                 m.call(*args)
#                             rescue Installer::PrebuildMissingRequirementError => e
#                                 expect(e.missing_pod_names).to match_array(['RxSwift'])
#                                 raise SpecError, '1'
#                             end
#                         }
#                         expect{
#                             @installer.install!
#                         }.to raise_error(SpecError)
#                     end
#
#                     it "should retry (regenerate the installer and install)" do
#                         expect(@installer).to receive(:regenerate_installer).exactly(:once).and_wrap_original { |m , *args|
#                             new_installer = m.call(*args)
#                             expect(new_installer).to receive(:install!).and_call_original
#                             new_installer
#                         }
#                         @installer.install!
#                     end
#
#                 end
#
#                 context 'when have nest requirements' do
#                     before(:each) do
#                         SpecHelper.stub_pod_dependencies(self, {
#                             RxCocoa: [['RxSwift', '>=4.4.0']],
#                             RxSwift: ['RxAtomic', '4.4.0'],
#                             RxAtomic: ['SnapKit', '>1.0']
#                         })
#                         @installer, @sandbox, @podfile =  Pod.build_installer do
#                             target 'A' do
#                                 pod "RxCocoa", '4.4.0', :binary => true
#                                 pod "RxSwift", '4.5.0', :binary => false
#                                 pod "SnapKit", '4.0.1', :binary => false
#                             end
#                         end
#                     end
#
#
#                     it "should retry twice" do
#                         # expect_any_instance_of(Installer).to receive(:regenerate_installer).exactly(2).and_call_original
#                         # @installer.install!
#                     end
#
#                 end
#
#             end
#         end
#     end
# end
