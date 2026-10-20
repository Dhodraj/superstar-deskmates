// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SpriteFolk",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "SpriteFolk",
            path: "Sources/SpriteFolk",
            resources: [.copy("Resources")]
        )
    ]
)
