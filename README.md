# ZenID sample application

Written in Swift 6 and SwiftUI with minimal supported of iOS 16. Application version corespond with ZenID SDK.

## How to make it run

Copy corresponding models into the `Models` folder, `LibZenid_iOS.xcframework` and `RecogLib_iOS.xcframework` into the `Libraries` folder. Open `ZenIDSample.xcproject`, change the signing and app ID, and compile.

## Structure

All ZenID backend calls are inside `Services/API.swift`. Each verifier scenario is covered inside `ViewModels`.

Quite interesting is `ZenidCameraView` which is UIViewRepresentable wrapper for `CameraView`.

## Important!

Please note that credentials here are stored in UserDefaults, which is not secure. For real applications, we recommend using different secure storage.

~ Happy coding! 🎉
