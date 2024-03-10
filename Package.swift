// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Firestonable",
	defaultLocalization: "en",
	platforms: [
		.iOS(.v17),
		.macOS(.v14),
		.watchOS(.v10),
		.tvOS(.v17)
	],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Firestonable",
            targets: ["Firestonable"]),
    ],
	dependencies: [
		.package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.21.0"),
		.package(url: "https://github.com/pinterest/PINCache.git", .upToNextMajor(from: "3.0.3"))
	],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Firestonable",
		dependencies: [
			"PINCache",
			.product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
			.product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
			.product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
			.product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
			.product(name: "FirebasePerformance", package: "firebase-ios-sdk"),
			.product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
		]),
        .testTarget(
            name: "FirestonableTests",
            dependencies: ["Firestonable"]),
    ]
)
