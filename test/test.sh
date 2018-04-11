#!/bin/sh
set -e

build() {
    xcodebuild -workspace Binary.xcworkspace -scheme Binary ONLY_ACTIVE_ARCH=YES  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO -quiet || exit 1 
}
		
python change_podfile.py "initial"
pod install
build

# 
python change_podfile.py "addSwiftPod"
pod install
build

# 
python change_podfile.py "addDifferentNamePod"
pod install
build

# 
python change_podfile.py "addSubPod"
pod install
build

# 
python change_podfile.py "deleteAPod"
pod install
build

#
python change_podfile.py "addVendoredLibPod"
pod install
build

#
python change_podfile.py "universalFlag"
pod install
build

#
exit 0
