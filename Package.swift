// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Deskmates",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Deskmates",
            path: "Sources/Deskmates",
            resources: [.copy("Resources")]
        )
    ]
)
