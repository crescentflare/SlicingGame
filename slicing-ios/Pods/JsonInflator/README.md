# JSON inflator

[![CI Status](http://img.shields.io/travis/crescentflare/JsonInflator.svg?style=flat)](https://travis-ci.org/crescentflare/JsonInflator)
[![License](https://img.shields.io/cocoapods/l/JsonInflator.svg?style=flat)](http://cocoapods.org/pods/JsonInflator)
[![Version](https://img.shields.io/cocoapods/v/JsonInflator.svg?style=flat)](http://cocoapods.org/pods/JsonInflator)
[![Version](https://img.shields.io/bintray/v/crescentflare/maven/JsonInflatorLib.svg?style=flat)](https://bintray.com/crescentflare/maven/JsonInflatorLib)

JSON inflator is a project to allow the creation of any object (including layouts and view components) from JSON on both iOS and Android and is an evolution of [ViewletCreator](https://github.com/crescentflare/ViewletCreator). It provides a way to make development more modular and dynamic. The example demonstrates how to use JSON inflator to prototype user interfaces real-time on multiple devices simultaneously.

Use the library together with [UniLayout](https://github.com/crescentflare/UniLayout) for simultaneous multi-platform development of UI on both iOS and Android.

For iOS this library is only available from Swift 5.0 and onwards. Older Swift versions can still use ViewletCreator (if possible).


### Features

* Provides a structure to create objects and class instances from JSON structures
* Has a central JSON inflator registry which can contain a list of object creators (inflatables) referenced by string, allowing them to be loosely coupled (and even allows nested object structures, like layouts)
* Adds utilities to safely fetch properties from a JSON structure with data conversion
* Share colors and coordinates/sizes by using color and dimension tables
* Define default attributes or custom attribute sets to fall back on for each inflatable (for example, to be used as styles)
* Define sub-attributes to be merged into the attribute list, or attributes to be excluded. For example, to define extra attributes which are specific for a platform


### iOS integration guide

The library is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod "JsonInflator", '~> 0.6.2'
```


### Android integration guide

When using gradle, the library can easily be imported into the build.gradle file of your project. Add the following dependency:

```
implementation 'com.crescentflare.jsoninflator:JsonInflatorLib:0.6.2'
```

Make sure that jcenter is added as a repository.


### Example

The provided example shows how to create view inflatables, register them and use them to make and prototype UI. In the example, it will use autolayout on iOS and viewgroup related layouts for Android.


### Status

The library is new but already provides a range of useful functionality. More features may be added in the future.
