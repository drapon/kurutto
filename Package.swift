// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Kurutto",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "Kurutto",
            targets: ["Kurutto"]),
    ],
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.0.0"),
    ],
    targets: [
        .target(
            name: "Kurutto",
            dependencies: [
                .product(name: "Lottie", package: "lottie-ios")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "KuruttoTests",
            dependencies: ["Kurutto"],
            path: "Tests"
        ),
    ]
)