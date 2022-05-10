// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "swift-log-supabase",
  platforms: [.iOS(.v11), .macOS(.v10_13)],
  products: [
    .library(
      name: "SupabaseLogging",
      targets: ["SupabaseLogging"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-log", from: "1.4.2")
  ],
  targets: [
    .target(
      name: "SupabaseLogging",
      dependencies: [
        .product(name: "Logging", package: "swift-log")
      ]),
    .testTarget(
      name: "SupabaseLoggingTests",
      dependencies: ["SupabaseLogging"],
      exclude: ["_Secrets.swift"]),
  ]
)
