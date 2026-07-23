// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BlackHoleBin",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "BlackHoleBin", targets: ["BlackHoleBin"])
    ],
    targets: [
        .executableTarget(
            name: "BlackHoleBin",
            path: "Sources/BlackHoleBin",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
