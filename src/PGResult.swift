//
//  PGResult.swift
//  PostgresConnector
//
//  Created by James Richard on 2/9/16.
//
//

import Cpq

public enum PGResultStatus {
    case successful
    case transferring
    case failed(String?)
    case unknown
}

public class PGResult {
    private let result: OpaquePointer
    public var columnCount: Int {
        return fields.count
    }
    public let rowCount: Int
    public let fields: [String]

    public var status: PGResultStatus {
        switch PQresultStatus(result) {
        case PGRES_EMPTY_QUERY, PGRES_COMMAND_OK, PGRES_TUPLES_OK, PGRES_SINGLE_TUPLE: return .successful
        case PGRES_COPY_OUT, PGRES_COPY_IN, PGRES_COPY_BOTH: return .transferring
        case PGRES_FATAL_ERROR, PGRES_BAD_RESPONSE: return .failed(String(validatingUTF8: PQresultErrorMessage(result)))
        default: return .unknown
        }
    }

    init(result: OpaquePointer) {
        self.result = result
        rowCount = Int(PQntuples(result))
        fields = (0 ..< Int32(PQnfields(result))).map { String(validatingUTF8: PQfname(result, $0))! }
    }
}

extension PGResult: Collection {
    public typealias Index = Int
    public typealias Iterator = AnyIterator<ResultRow>.Iterator

    public var startIndex: Index {
        return 0
    }

    public var endIndex: Index {
        return rowCount
    }

    public subscript(index: Index) -> ResultRow {
        precondition(index < endIndex)
        return ResultRow(result: result, row: index, fields: fields)
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

public struct ResultRow {
    private let result: OpaquePointer
    private let row: Int
    public var columnCount: Int {
        return fields.count
    }

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

extension ResultRow: Collection {
    public typealias Index = Int
    public typealias Element = (String, PGValue)
    public typealias Iterator = AnyIterator<Element>.Iterator

    public var startIndex: Index {
        return 0
    }

    public var endIndex: Index {
        return columnCount
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



