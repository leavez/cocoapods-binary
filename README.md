
<p align="center"><img src="/test/logo.png" width="622"></p>

[![Build Status](https://travis-ci.org/leavez/cocoapods-binary.svg?branch=master)](https://travis-ci.org/leavez/cocoapods-binary)

A CocoaPods plugin to integrate pods in form of prebuilt frameworks, not source code, by adding **just one flag** in podfile. Speed up compiling dramatically.

Good news: Introduction on cocoapods offical site: [Pre-compiling dependencies](http://guides.cocoapods.org/plugins/pre-compiling-dependencies.html) ( NOTE: This plugin is a community work, not official.)


## Why

You may wonder why CocoaPods doesn't have a function to integrate libs in form of binaries, if there are dozens or hundreds of pods in your podfile and compile them for a great many times meaninglessly. Too many source code of libs slow down your compile and the response of IDE (e.g. code completion), and then reduce work efficiency, leaving us time to think about the meaning of life.

This plugin implements this simple wish. Replace the source code in pod target with prebuilt frameworks.

Why don't use Carthage? While Carthage also integrates libs in form of frameworks, there several reasons to use CocoaPods with this plugin:

- Pod is a good simple form to organize files, manage dependencies. (private or local pods)
- Fast switch between source code and binary, or partial source code, partial binaries.
- Some libs don't support Carthage.

## How it works

It will compile the source code of pods during the pod install process, and make CocoaPods use them. Which pod should be compiled is controlled by the flag in Podfile.

#### Under the hood

( You could leave this paragraph for further reading, and try it now. )

The plugin will do a separated completed 'Pod install' in the standard pre-install hook. But we filter the pods by the flag in Podfile here. Then build frameworks with this generated project by using xcodebuild. Store the frameworks in `Pods/_Prebuild` and save the manifest.lock file for the next pod install.

Then in the flowing normal install process, we hook the integration functions to modify pod specification to using our frameworks.

## Installation

    $ gem install cocoapods-binary

## Usage

``` ruby
plugin 'cocoapods-binary'

use_frameworks!
# all_binary!

target "HP" do
    pod "ExpectoPatronum", :binary => true
end
```

- Add `plugin 'cocoapods-binary'` in the head of Podfile 
- Add `:binary => true` as a option of one specific pod, or add `all_binary!` before all targets, which makes all pods binaries.
- pod install, and that's all

**Note**: cocoapods-binary require `use_frameworks!`. If your worry about the boot time and other problems introduced by dynamic framework, static framework is a good choice. Another [plugin](https://github.com/leavez/cocoapods-static-swift-framework) made by me to make all pods static frameworks is recommended.

#### Options

If you want to disable binary for a specific pod when using `all_binary!`, place a `:binary => false` to it.

If your `Pods` folder is excluded from git, you may add `keep_source_code_for_prebuilt_frameworks!` in the head of Podfile to speed up pod install, as it won't download all the sources every time prebuilt pods have changes.

If bitcode is needed, add a `enable_bitcode_for_prebuilt_frameworks!` before all targets in Podfile

if you want to share prebuilt frameworks for different projects or for CI builds, you may add `use_shared_cache!` in the head of Podfile to speed up pod install, as it will reuse frameworks from common cache folder(`~Library/Caches/CocoaPods/Prebuilt` by default). 


#### Known Issues

- doesn't support watchos now
- ~~dSYM files is missing for dynamic frameworks using this plugin. Workaround: Don't use this plugin for a release build. Add a if condition with ENV around `plugin 'cocoapods-binary'`. [(detail)](https://github.com/leavez/cocoapods-binary/issues/44)~~ (fix in 0.4.2)

## License

MIT

Appreciate a 🌟 if you like it. 
