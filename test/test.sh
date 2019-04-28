#!/bin/sh
set -e

build() {
    xcodebuild -workspace Binary.xcworkspace -scheme Binary ONLY_ACTIVE_ARCH=YES  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO -quiet || exit 1 
}	
		
rm -rf Pods

cases=("initial" "addSwiftPod" "revertToSourceCode" "addDifferentNamePod" "addSubPod" "deleteAPod" "addVendoredLibPod" "universalFlag" "multiplePlatforms" "multiplePlatformsWithALLFlag")
for action in ${cases[@]}; do
    python change_podfile.py ${action}
    bundle exec pod install
    build
done

exit 0
