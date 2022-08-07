// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "FormattedResponse",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(name: "FormattedResponse", targets: ["FormattedResponse"])
    ],
    dependencies: [
         .package(url: "https://github.com/vapor/vapor.git", from: "4.55.0"),
    ],
    targets: [
        .target(name: "FormattedResponse", dependencies: [.product(name: "Vapor", package: "vapor")])
    ]
)
