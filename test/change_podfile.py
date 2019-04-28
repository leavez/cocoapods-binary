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

pod "RxCocoa", :binary => true
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

pod "RxCocoa", :binary => true
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


if __name__ == "__main__":
    arg = sys.argv[1]
    print("===================\nchange Podfile to: " + arg + "\n")
    save_to_podfile(globals()[arg]())