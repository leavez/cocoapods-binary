import os
import sys

def wrapper(content):
    return """
platform :ios, '9.0'
inhibit_all_warnings!
use_frameworks!
plugin "cocoapods-binary"

target 'Binary' do
%s
end
    """ % content

def save_to_podfile(text):
    path = os.path.dirname(os.path.abspath(__file__))
    path += "/Podfile"
    file = open(path, "w+")
    file.write(text[0])
    file.close()

    path = os.path.dirname(os.path.abspath(__file__))
    path += "/Binary/import.swift"
    file = open(path, "w+")
    file.write(text[1])
    file.close()

    path = os.path.dirname(os.path.abspath(__file__))
    path += "/BinaryWatch Extension/import.swift"
    file = open(path, "w+")
    file.write( "" if len(text) <= 2 else text[2])
    file.close()

    if len(text) > 3:
        path = os.path.dirname(os.path.abspath(__file__))
        path += "/Podfile.lock"
        file = open(path, "w+")
        file.write(text[3])
        file.close()



def initial():
    return (wrapper(
"""
keep_source_code_for_prebuilt_frameworks!

pod "Masonry"
"""), 
"""
import Masonry
class A {
    let d = UIView().mas_top
}
""")

def addSwiftPod():
    return (wrapper(
"""
keep_source_code_for_prebuilt_frameworks!

pod "RxCocoa", "~> 4.0", :binary => true
pod "Literal", :binary => true
"""), 
"""
import RxCocoa
import Literal
class A {
    let a: CGRect = [1,2,3,4]
    func dd() { NSObject().rx.observe(CGRect.self, "frame") }
}
""")

def revertToSourceCode():
    return (wrapper(
"""
keep_source_code_for_prebuilt_frameworks!

pod "RxCocoa", "~> 4.0", :binary => true
pod "Literal"
"""), 
"""
import RxCocoa
import RxSwift
import Literal
class A {
    let a: CGRect = [1,2,3,4]
    let b = Observable.just(1)
    func dd() { NSObject().rx.observe(CGRect.self, "frame") }
}
""") 

def addDifferentNamePod():
    return (wrapper(
"""
enable_bitcode_for_prebuilt_frameworks!

pod "Masonry", :binary => true
pod "Literal", :binary => true
pod "lottie-ios", :binary => true
"""), 
"""
import Masonry
import Literal
import Lottie
class A {
    let a: CGRect = [1,2,3,4]
    let a2 = AnimationView.self
    let d = UIView().mas_top
}
""") 


def addSubPod():
    return (wrapper(
"""
pod "Masonry", :binary => true
pod "Literal", :binary => true
pod "lottie-ios", :binary => true
pod "AFNetworking/Reachability", :binary => true
""") , 
"""
import Masonry
import Literal
import Lottie
import AFNetworking
class A {
    let a: CGRect = [1,2,3,4]
    let a2 = AnimationView.self
    let b = AFNetworkReachabilityManager()
    let d = UIView().mas_top
}
""") 

def addVendoredLibPod():
    return (wrapper(
"""
pod "Literal", :binary => true
pod "AFNetworking/Reachability", :binary => true
pod "Instabug", :binary => true
pod "GrowingIO", :binary => true
""") , 
"""
import Literal
import AFNetworking
import Instabug
class A {
    let a: CGRect = [1,2,3,4]
    let b = AFNetworkReachabilityManager()
    let c = Instabug.self
}
""") 

def deleteAPod():
    return (wrapper(
"""
pod "Literal", :binary => true
pod "AFNetworking/Reachability", :binary => true
""") , 
"""
import Literal
import AFNetworking
class A {
    let a: CGRect = [1,2,3,4]
    let b = AFNetworkReachabilityManager()
}
""") 

def universalFlag():
    return (wrapper(
"""
all_binary!

pod "Literal"
pod "AFNetworking/Reachability"
""") , 
"""
import Literal
import AFNetworking
class A {
    let a: CGRect = [1,2,3,4]
    let b = AFNetworkReachabilityManager()
}
""") 
    
def multiplePlatforms():
    return (wrapper(
"""
pod "Literal", :binary => true
pod "AFNetworking/Serialization", :binary => true
end

target 'BinaryWatch Extension' do
    platform :watchos
    pod "AFNetworking/Serialization", :binary => true
""") , 
"""
import Literal
import AFNetworking
class A {
    let a: CGRect = [1,2,3,4]
    func dd() {  _ = AFURLRequestSerializationErrorDomain   }
}
""",
"""
import AFNetworking
class A {
    func dd() { _ = AFURLRequestSerializationErrorDomain }
}
"""
) 

def multiplePlatformsWithALLFlag():
    return (wrapper(
"""
all_binary!

pod "Literal"
pod "AFNetworking/Serialization"
end

target 'BinaryWatch Extension' do
    platform :watchos
    pod "AFNetworking/Serialization"
""") , 
"""
import Literal
import AFNetworking
class A {
    let a: CGRect = [1,2,3,4]
    func dd() {  _ = AFURLRequestSerializationErrorDomain   }
}
""",
"""
import AFNetworking
class A {
    func dd() { _ = AFURLRequestSerializationErrorDomain }
}
"""
) 

def oldPodVersion():
    return (wrapper(
"""
pod "ReactiveSwift", "= 3.0.0", :binary => true
""") ,
"""
import ReactiveSwift
class A {
    // Works on 3.x but not 4.x
    let a = A.b(SignalProducer<Int, NSError>.empty)
    static func b<U: BindingSource>(_ b: U) -> Bool {
        return true
    }
}
"""
)

def upgradePodVersion():
    return (wrapper(
"""
pod "ReactiveSwift", "= 4.0.0", :binary => true
""") ,
"""
import ReactiveSwift
class A {
    func b() {
        // Works on 4.x but not 3.x
        Lifetime.make().token.dispose()
    }
}
"""
)


def originalPodfileAndLockfileVersion():
    return (wrapper(
"""
pod "Result", "= 3.2.2", :binary => true
""") ,
"""
import Result
class A {
    // Works on 3.x but not 4.x
    var err: ErrorProtocolConvertible?
}
""", "",
"""
PODS:
  - Result (3.2.2)

DEPENDENCIES:
  - Result (= 3.2.2)

SPEC REPOS:
  https://github.com/cocoapods/specs.git:
    - Result

SPEC CHECKSUMS:
  Result: 4edd39003fdccf281d418ee1b006571f70123250

PODFILE CHECKSUM: 578d759c1f6329e159731bc0a232fb9051977130

COCOAPODS: 1.6.1
"""
)

def upgradePodfileAndLockfileVersion():
    return (wrapper(
"""
pod "Result", "= 4.0.0", :binary => true
""") ,
"""
import Result
class A {
    // Works on 4.x but not 3.x
    var err: ErrorConvertible?
}
""", "",
"""
PODS:
  - Result (4.0.0)

DEPENDENCIES:
  - Result (= 4.0.0)

SPEC REPOS:
  https://github.com/cocoapods/specs.git:
    - Result

SPEC CHECKSUMS:
  Result: 7645bb3f50c2ce726dd0ff2fa7b6f42bbe6c3713

PODFILE CHECKSUM: ee7fa7b9f6dade6905c2b00142c54f164bdc2ceb

COCOAPODS: 1.6.1
"""
)

def originalLockfileVersion():
    return (wrapper(
"""
pod "Result", :binary => true
""") ,
"""
import Result
class A {
    // Works on 3.x but not 4.x
    var err: ErrorProtocolConvertible?
}
""", "",
"""
PODS:
  - Result (3.2.2)

DEPENDENCIES:
  - Result

SPEC REPOS:
  https://github.com/cocoapods/specs.git:
    - Result

SPEC CHECKSUMS:
  Result: 4edd39003fdccf281d418ee1b006571f70123250

PODFILE CHECKSUM: 8705dea54636097dca87d2a49ac6963c842b6eb4

COCOAPODS: 1.6.1
"""
)

def upgradeLockfileVersion():
    return (wrapper(
"""
pod "Result", :binary => true
""") ,
"""
import Result
class A {
    // Works on 4.x but not 3.x
    var err: ErrorConvertible?
}
""", "",
"""
PODS:
  - Result (4.0.0)

DEPENDENCIES:
  - Result

SPEC REPOS:
  https://github.com/cocoapods/specs.git:
    - Result

SPEC CHECKSUMS:
  Result: 7645bb3f50c2ce726dd0ff2fa7b6f42bbe6c3713

PODFILE CHECKSUM: 8705dea54636097dca87d2a49ac6963c842b6eb4

COCOAPODS: 1.6.1
"""
)

if __name__ == "__main__":
    arg = sys.argv[1]
    print("===================\nchange Podfile to: " + arg + "\n")
    save_to_podfile(globals()[arg]())