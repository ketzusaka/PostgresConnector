import PackageDescription

let package = Package(
    name: "PostgresConnector",
    dependencies: [
        .Package(url: "../libpq", majorVersion: 1),
.Package(url: "../libdispatch", majorVersion: 1)
    ]
)

