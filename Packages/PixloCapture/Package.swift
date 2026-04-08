// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "PixloCapture",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PixloCapture", targets: ["PixloCapture"]),
    ],
    targets: [
        .target(name: "PixloCapture"),
    ]
)
