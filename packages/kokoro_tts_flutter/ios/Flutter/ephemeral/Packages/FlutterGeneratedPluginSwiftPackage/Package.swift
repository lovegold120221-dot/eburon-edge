// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "audio_session", path: "../.packages/audio_session-0.2.4"),
        .package(name: "flutter_onnxruntime", path: "../.packages/flutter_onnxruntime-1.8.3"),
        .package(name: "integration_test", path: "../.packages/integration_test"),
        .package(name: "just_audio", path: "../.packages/just_audio-0.10.6"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "audio-session", package: "audio_session"),
                .product(name: "flutter-onnxruntime", package: "flutter_onnxruntime"),
                .product(name: "integration-test", package: "integration_test"),
                .product(name: "just-audio", package: "just_audio"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
