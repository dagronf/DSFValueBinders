// swift-tools-version:5.3

import PackageDescription

let package = Package(
	name: "DSFValueBinders",
	platforms: [
		.macOS(.v10_11),
		.iOS(.v13),
		.tvOS(.v13)
	],
	products: [
		.library(name: "DSFValueBinders", targets: ["DSFValueBinders"]),
		.library(name: "DSFValueBinders-static", type: .static, targets: ["DSFValueBinders"]),
		.library(name: "DSFValueBinders-shared", type: .dynamic, targets: ["DSFValueBinders"]),
	],
	targets: [
		.target(
			name: "DSFValueBinders",
			dependencies: []
		),
		.testTarget(
			name: "DSFValueBindersTests",
			dependencies: ["DSFValueBinders"]
		)
	]
)
