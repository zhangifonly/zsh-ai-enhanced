// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "iZshNative",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "iZshNative", targets: ["iZshNative"])
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "iZshNative",
            dependencies: ["SwiftTerm"]
        )
    ]
)
