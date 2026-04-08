// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "PixloShared",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PixloShared", targets: ["PixloShared"]),
    ],
    targets: [
        .target(name: "PixloShared"),
    ]
)
