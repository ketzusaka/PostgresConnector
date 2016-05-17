//
//  PGResult.swift
//  PostgresConnector
//
//  Created by James Richard on 2/9/16.
//
//

#if os(Linux)
    import CPostgreSQLLinux
#else
    import CPostgreSQLMac
#endif

/// An enum representing the general status of a `PGResult`
public enum PGResultStatus {
    case successful
    case transferring
    case failed(String?)
    case unknown
}

extension PGResultStatus: Equatable { }

public func ==(lhs: PGResultStatus, rhs: PGResultStatus) -> Bool {
    switch (lhs, rhs) {
    case (.successful, .successful), (.transferring, .transferring), (.unknown, .unknown): return true
    case (.failed(let f1), .failed(let f2)): return f1 == f2
    default: return false
    }
}

/// The result of an executed postgres query
public class PGResult {
    let result: OpaquePointer

    /// The number of fields contained in the result
    public var fieldCount: Int {
        return fields.count
    }

    /// The number of rows in the result
    public let rowCount: Int

    /// The fields contained in the result
    public let fields: [String]

    /// The status for the result
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

    deinit {
        PQclear(result)
    }
}

extension PGResult: Collection {
    public typealias Index = Int
    public typealias Iterator = AnyIterator<PGRow>.Iterator
    public typealias SubSequence = Array<PGRow>

    public var startIndex: Index {
        return 0
    }

    public var endIndex: Index {
        return rowCount
    }

    public subscript(position: Index) -> PGRow {
        precondition(position < endIndex)
        return PGRow(result: self, row: position, fields: fields)
    }

    public subscript(bounds: Range<Index>) -> SubSequence {
        return (bounds.lowerBound ..< bounds.upperBound).reduce([PGRow]()) { memo, index in
            var memo = memo
            memo.append(PGRow(result: self, row: index, fields: fields))
            return memo
        }
    }

    public func index(after i: Index) -> Index {
        return i + 1
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
