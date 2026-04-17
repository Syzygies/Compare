// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "perms",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(name: "perms", targets: ["perms"])
    ],
    targets: [
        .executableTarget(
            name: "perms",
            path: "src",
            swiftSettings: [
                .unsafeFlags(["-O"])
            ]
        )
    ]
)