import os
import sys

def wrapper(content):
    return """
platform :ios, '9.0'
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
    file.write(text)
    file.close()


def initial():
    return wrapper(
"""
pod "Masonry"
""")

def addSwiftPod():
    return wrapper(
"""
pod "Masonry", :binary => true
pod "Literal", :binary => true
""")

def addDifferentNamePod():
    return wrapper(
"""
pod "Masonry", :binary => true
pod "Literal", :binary => true
pod "lottie-ios", :binary => true
""") 

def addSubPod():
    return wrapper(
"""
pod "Masonry", :binary => true
pod "Literal", :binary => true
pod "lottie-ios", :binary => true
pod "AFNetworking/Reachability", :binary => true
""") 

def addVendoredLibPod():
    return wrapper(
"""
pod "Literal", :binary => true
pod "AFNetworking/Reachability", :binary => true
pod "Instabug", :binary => true
""") 

def deleteAPod():
    return wrapper(
"""
pod "Literal", :binary => true
pod "AFNetworking/Reachability", :binary => true
""") 



if __name__ == "__main__":
    arg = sys.argv[1]
    print("change Podfile to: " + arg)
    if arg == "initial":
        save_to_podfile(initial())
    elif arg == "addSwiftPod":
        save_to_podfile(addSwiftPod())
    elif arg == "addDifferentNamePod":
        save_to_podfile(addDifferentNamePod())
    elif arg == "addSubPod":
        save_to_podfile(addSubPod())
    elif arg == "deleteAPod":
        save_to_podfile(deleteAPod())
    elif arg == "addVendoredLibPod":
        save_to_podfile(addVendoredLibPod())
