//
//  PostgresDB.swift
//  PostgresConnector
//
//  Created by James Richard on 2/9/16.
//
//

#if os(Linux)
    import Glibc
    import CDispatch
#else
    import Darwin
    import Dispatch
#endif

import Cpq

/*protocol PostgresNotifyDelegate: class {
    func postgresDB(postgresDB: PostgresDB, didReceiverNotification notification: String)
}*/

public class PostgresDB {
    let host: String
    let username: String
    let password: String?
    let port: Int
    let databaseName: String
//    weak var notifyDelegate: PostgresNotifyDelegate?

    public init(host: String = "localhost", username: String, password: String? = nil, port: Int = 5432, databaseName: String) {
        self.host = host
        self.username = username
        self.password = password
        self.port = port
        self.databaseName = databaseName
    }

    private var connection: COpaquePointer?

    public func connect() throws {
        guard connection == nil else {
            throw PostgresError.ConnectionAlreadyOpen
        }

        var connectionString = "host='\(host)' port='\(port)' host='\(host)' dbname='\(databaseName)'"

        if let pw = password {
            connectionString += " password='\(pw)'"
        }

        connection = PQconnectdb(connectionString)
        let status = PQstatus(connection!)

        switch status {
        case CONNECTION_OK:
            print("Connected!")
            break
        default:
            let error = String.fromCString(PQerrorMessage(connection!))
            connection = nil
            throw PostgresError.CouldntConnect(error)

        }
    }

    public func executeQuery(query: String) throws -> PostgresResult {
        guard let conn = connection else {
            throw PostgresError.InvalidConnection
        }

        let res = PQexec(conn, query)
        return PostgresResult(result: res)
    }
}


public enum PostgresError: ErrorType {
    case ConnectionAlreadyOpen
    case CouldntConnect(String?)
    case InvalidConnection
    case IncorrectResult
}
