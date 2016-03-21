//
//  PGValue.swift
//  PostgresConnector
//
//  Created by James Richard on 3/16/16.
//
//

#if os(Linux)
    import CPostgreSQLLinux
#else
    import CPostgreSQLMac
#endif

public typealias Byte = UInt8

// Inspiration: https://github.com/Zewo/SQL/blob/master/Sources/SQL/Core/Data.swift

public protocol PostgresDataConvertible {
    init(rawPostgresData: [Byte]) throws
}

extension String: PostgresDataConvertible {
    public init(rawPostgresData: [Byte]) throws {
        var string = ""
        var decoder = UTF8()
        var generator = rawPostgresData.makeIterator()

        DECODE_LOOP: while true {
            let decodingResult = decoder.decode(&generator)
            switch decodingResult {
            case .scalarValue(let char): string.append(char)
            case .emptyInput: break DECODE_LOOP
            case .error: throw SQLDataConvertionError.conversionFailed
            }
        }

        self = string
    }
}

extension Int: PostgresDataConvertible {
    public init(rawPostgresData: [Byte]) throws {
        guard let value = Int(try String(rawPostgresData: rawPostgresData)) else {
            throw SQLDataConvertionError.conversionFailed
        }

        self = value
    }
}

extension Double: PostgresDataConvertible {
    public init(rawPostgresData: [Byte]) throws {
        guard let value = Double(try String(rawPostgresData: rawPostgresData)) else {
            throw SQLDataConvertionError.conversionFailed
        }

        self = value
    }
}

extension Bool: PostgresDataConvertible {
    public init(rawPostgresData: [Byte]) throws {
        let string = try String(rawPostgresData: rawPostgresData)

        if string == "t" {
            self = true
        } else if string == "f" {
            self = false
        } else {
            throw SQLDataConvertionError.conversionFailed
        }
    }
}

public enum SQLDataConvertionError: ErrorProtocol {
    case conversionFailed
}
