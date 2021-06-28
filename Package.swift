// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "FastDDS",
    products: [
        .library(name: "FastDDS", targets: ["FastDDS"])
    ],
    targets: [
        .binaryTarget(name: "FastDDS",
                      url: "https://github.com/ZhenKaiJia/FastDDSPrebuild/releases/download/2.1.0/fastrtps-2.1.0.xcframework.zip",
                      checksum: "")
    ]
)
