#!/bin/sh
set -e

build() {
    xcodebuild -workspace Binary.xcworkspace -scheme Binary ONLY_ACTIVE_ARCH=YES  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO -quiet || exit 1 
}	
		
rm -rf Pods

python change_podfile.py "initial"
pod install
build

# 
python change_podfile.py "addSwiftPod"
pod install
build

# 
python change_podfile.py "revertToSourceCode"
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
python change_podfile.py "multiplePlatforms"
pod install
build

#
python change_podfile.py "multiplePlatformsWithALLFlag"
pod install
build

#
exit 0
