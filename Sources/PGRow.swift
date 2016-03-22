//
//  PGRow.swift
//  PostgresConnector
//
//  Created by James Richard on 3/20/16.
//
//

#if os(Linux)
    import CPostgreSQLLinux
    import Glibc
#else
    import CPostgreSQLMac
    import Darwin
#endif

// Inspiration for value reading: https://github.com/Zewo/SQL

/// A row of data from a postgres query
public struct PGRow {
    private let result: OpaquePointer
    private let row: Int

    /// The number of columns in the row
    public var fieldCount: Int {
        return fields.count
    }

    /// The fields contained in the row
    public let fields: [String]

    init(result: OpaquePointer, row: Int, fields: [String]) {
        self.result = result
        self.row = row
        self.fields = fields
    }

    /**
     Reads a value for a given `field`, attempting to convert it to the expected type.
     
     Null values are not allowed. This will raise an error if the value in the db is null.
     
     - parameter    field: The name of the field to read
     - returns:     The converted value, if non-null and successfully converted
    */
    public func value<Value: PostgresDataConvertible>(for field: String) throws -> Value {
        return try makeValue(for: field, allowingNull: false)!
    }

    /**
     Reads a value for a given `field`, attempting to convert it to the expected type.
     
     If the value is null this will return nil.

     - parameter    field: The name of the field to read
     - returns:     The converted value, if non-null and successfully converted
     */
    public func value<Value: PostgresDataConvertible>(for field: String) throws -> Value? {
        return try makeValue(for: field, allowingNull: true)
    }

    private func makeValue<Value: PostgresDataConvertible>(for field: String, allowingNull: Bool) throws -> Value? {
        guard let fieldIndex = fields.index(of: field) else {
            throw PostgresRowError.invalidFieldName
        }

        let row = Int32(self.row)
        let field = Int32(fieldIndex)

        guard PQgetisnull(result, row, field) == 0 else {
            if allowingNull {
                return nil
            } else {
                throw PostgresRowError.unexpectedNullValue
            }
        }

        let rawData = PQgetvalue(result, row, field)
        let rawDataLength = Int(PQgetlength(result, row, field))
        var data = [UInt8](repeating: 0, count: rawDataLength)
        memcpy(&data, rawData, rawDataLength)

        return try Value(rawPostgresData: data)
    }
}

public enum PostgresRowError: ErrorProtocol {
    case invalidFieldName
    case unexpectedNullValue
}
