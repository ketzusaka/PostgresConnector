//
//  PGValue.swift
//  PostgresConnector
//
//  Created by James Richard on 3/16/16.
//
//

import Cpq

/*
 The case for a `PGValue` is determined by its Oid. Below is a list of Oids from a table where I
 added a column for each one that was listed on http://www.postgresql.org/docs/9.3/static/datatype.html

 integer                |       23
 text                   |       25
 character(8)           |     1042
 smallint               |       21
 bigint                 |       20
 numeric(4,2)           |     1700
 real                   |      700
 double precision       |      701
 float                  |      700
 bit(8)                 |     1560
 boolean                |       16
 bytea                  |       17
 character varying(100) |     1043
 cidr                   |      650
 circle                 |      718
 inet                   |      869
 json                   |      114
 line                   |      628
 lseg                   |      601
 macaddr                |      829
 money                  |      790
 path                   |      602
 point                  |      600
 polygon                |      604
 tsquery                |     3615
 tsvector               |     3614
 txid_snapshot          |     2970
 uuid                   |     2950
 xml                    |      142
 date                   |     1082
 timestamp w/o TZ       |     1114
 timestamp w/ TZ        |     1184
 time w/o TZ            |     1083
 time w/ TZ             |     1266
 interval               |     1186

 The query for retreiving the above information was: 
 SELECT attname,atttypid FROM pg_attribute WHERE attrelid = (SELECT oid FROM pg_class WHERE relname = 'field_testing');
 */


///A value from a Postgres DB. If the column is an unknown type we'll store it in the `unknown` case.
public enum PGValue {
    case int(Int64)
    case string(String)
    case bool(Bool)
    case double(Double)
    case null
    case unknown(String)

    init(value: Swift.String?, withType type: Oid) {
        guard let v = value else {
            self = .null
            return
        }

        switch type {
        case 20, 21, 23:
            guard let intValue = Int64(v) else {
                self = .null
                return
            }
            self = int(intValue)
        case 17, 18, 25, 1042, 1043:
            self = .string(v)
        case 1700, 700, 701:
            guard let doubleValue = Double(v) else {
                self = .null
                return
            }

            self = .double(doubleValue)
        case 16:
            if v == "t" {
                self = .bool(true)
            } else if v == "f" {
                self = .bool(false)
            } else {
                self = .null
            }

        default: self = .unknown(v)
        }
    }
    
}

extension PGValue: CustomStringConvertible {
    public var description: Swift.String {
        switch self {
        case .int(let value): return "Int(\(value))"
        case .string(let value): return "String(\(value))"
        case .double(let value): return "Double(\(value))"
        case .bool(let value): return "Bool(\(value))"
        case .unknown(let value): return "Unknown(\(value))"
        case .null: return "Null"
        }
    }
}
