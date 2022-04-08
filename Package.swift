// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "swift-log-supabase",
  products: [
    .library(
      name: "SupabaseLogger",
      targets: ["SupabaseLogger"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-log", from: "1.4.2")
  ],
  targets: [
    .target(
      name: "SupabaseLogger",
      dependencies: [
        .product(name: "Logging", package: "swift-log")
      ]),
    .testTarget(
      name: "SupabaseLoggerTests",
      dependencies: ["SupabaseLogger"]),
  ]
)
