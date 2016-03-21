import PackageDescription

let package = Package(
    name: "PostgresConnector",
    dependencies: [
                      .Package(url: "https://github.com/qutheory/cpostgresql.git", majorVersion: 0, minor: 1)
    ]
)
