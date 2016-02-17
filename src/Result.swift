//
//  Result.swift
//  PostgresConnector
//
//  Created by James Richard on 2/9/16.
//
//

import Cpq

public enum PostgresResultStatus {
    case Successful
    case Transferring
    case Failed(String?)
    case Unknown
}

public class PostgresResult {
    private let result: COpaquePointer

    public var status: PostgresResultStatus {
        switch PQresultStatus(result) {
        case PGRES_EMPTY_QUERY, PGRES_COMMAND_OK, PGRES_TUPLES_OK, PGRES_SINGLE_TUPLE: return .Successful
        case PGRES_COPY_OUT, PGRES_COPY_IN, PGRES_COPY_BOTH: return .Transferring
        case PGRES_FATAL_ERROR, PGRES_BAD_RESPONSE: return .Failed(String.fromCString(PQresultErrorMessage(result)))
        default: return .Unknown
        }
    }

    init(result: COpaquePointer) {
        self.result = result
    }

    // TODO: Make this lazy?
    //    var rows: LazyCollection<ResultRow> {
    //        return LazyCollection<ResultRow>()
    //    }

    public var columnCount: Int {
        return Int(PQnfields(result))
    }

    public var rowCount: Int {
        return Int(PQntuples(result))
    }

    public var rows: [ResultRow] {
        return (0 ..< Int(PQntuples(result))).map {
            ResultRow(result: self.result, row: $0)
        }
    }
}

public struct ResultRow {
    private let result: COpaquePointer
    private let row: Int

    init(result: COpaquePointer, row: Int) {
        self.result = result
        self.row = row
    }

    public var columnCount: Int {
        return Int(PQnfields(result))
    }

    public var columns: [PostgresValue] {
        return (0 ..< columnCount).map {
            PostgresValue(value: String.fromCString(PQgetvalue(self.result, Int32(self.row), Int32($0))), withType: PQftype(self.result, Int32($0)))
        }
    }
}

public enum PostgresValue {
    case Int(Swift.Int64)
    case String(Swift.String)
    case Bool(Swift.Bool)
    case Null
    case Unknown

    init(value: Swift.String?, withType type: Oid) {
        guard let v = value else {
            self = .Null
            return
        }

        switch type {
        case 20, 21, 23:
            guard let intValue = Swift.Int64(v) else {
                self = .Null
                return
            }
            self = Int(intValue)
        case 17, 18, 25:
            self = .String(v)

        case 16:
            if v == "t" {
                self = .Bool(true)
            } else {
                self = .Bool(false)
            }

        default: self = .Unknown
        }
    }
    
    
}
