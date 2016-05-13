import PackageDescription

let package = Package(
    name: "PostgresConnector",
    dependencies: [
                      .Package(url: "https://github.com/qutheory/cpostgresql.git", majorVersion: 0, minor: 1),
		      .Package(url: "https://github.com/Zewo/String.git", majorVersion: 0, minor: 7)
    ]
)
