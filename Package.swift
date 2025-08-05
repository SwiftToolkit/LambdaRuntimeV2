// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LambdaV2Sample",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
      .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", from: "2.0.0-beta.1"),
      .package(url: "https://github.com/swift-server/swift-aws-lambda-events.git", from: "1.1.0"),
      .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.26.1"),
      .package(url: "https://github.com/swift-cloud/swift-cloud.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "LambdaExtras",
            dependencies: [
                .product(name: "AWSLambdaEvents", package: "swift-aws-lambda-events"),
            ]
        ),
        .executableTarget(
            name: "BackgroundExecution",
            dependencies: [
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                .product(name: "AWSLambdaEvents", package: "swift-aws-lambda-events"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .target(name: "LambdaExtras"),
            ]
        ),
        .executableTarget(
            name: "StreamingResponse",
            dependencies: [
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                .product(name: "AWSLambdaEvents", package: "swift-aws-lambda-events"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .target(name: "LambdaExtras"),
            ]
        ),
        .executableTarget(
            name: "Infra",
            dependencies: [
                .product(name: "Cloud", package: "swift-cloud")
            ]
        ),
    ]
)
