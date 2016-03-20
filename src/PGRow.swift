//
//  PGRow.swift
//  PostgresConnector
//
//  Created by James Richard on 3/20/16.
//
//

import Cpq

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

    public subscript(index: String) -> PGValue? {
        guard let columnIndex = fields.index(of: index) else { return nil }
        return self[columnIndex].1
    }
}

extension PGRow: Collection {
    public typealias Index = Int
    public typealias Element = (String, PGValue)
    public typealias Iterator = AnyIterator<Element>.Iterator

    public var startIndex: Index {
        return 0
    }

    public var endIndex: Index {
        return fieldCount
    }

    public subscript(index: Index) -> Element {
        precondition(index < endIndex)
        let type = PQftype(self.result, Int32(index))
        let field = fields[index]
        return (field, PGValue(value: String(validatingUTF8: PQgetvalue(self.result, Int32(self.row), Int32(index))), withType: type))
    }

    public func makeIterator() -> Iterator {
        var currentIndex = startIndex
        return AnyIterator {
            guard currentIndex < self.endIndex else { return nil }
            let value = self[currentIndex]
            currentIndex += 1
            return value
        }
    }
}