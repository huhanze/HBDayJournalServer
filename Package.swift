// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "HBDayJournalServer",
    products: [
        .library(name: "HBDayJournalServer", targets: ["App"]),
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),

        .package(url: "https://github.com/vapor/fluent-mysql.git", from: "3.0.0"),
        
        // 👤 Authentication and Authorization framework for Fluent.
        .package(url: "https://github.com/vapor/auth.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/crypto.git", .upToNextMajor(from: "3.0.0")),
    ],
    targets: [
        .target(name: "App", dependencies: ["FluentMySQL", "Vapor","Authentication","Crypto", "Random"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)

