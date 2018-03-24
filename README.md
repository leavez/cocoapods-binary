# cocoapods-binary

A cocoapods plugin that enables to integrate pod in form of prebuilt framework, not source code, with **just one flag** in podfile. This can dramatically speed up your compile time.

(This project is still in early stage.)

## Installation

    $ gem install cocoapods-binary

## Usage

Add this in the podfile:

``` ruby
plugin 'cocoapods-binary'

target "HP" do
    pod "ExpectoPatronum", :binary => true
end
```
