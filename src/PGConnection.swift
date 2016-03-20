//
//  PGConnection.swift
//  PostgresConnector
//
//  Created by James Richard on 2/9/16.
//
//

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

import Cpq

public class PGConnection {
    let host: String
    let username: String
    let password: String?
    let port: Int
    let databaseName: String
    private let connectionLock = NSLock()

    public init(host: String = "localhost", username: String, password: String? = nil, port: Int = 5432, databaseName: String) {
        self.host = host
        self.username = username
        self.password = password
        self.port = port
        self.databaseName = databaseName
    }

    private var connection: OpaquePointer?

    public func connect() throws {
        connectionLock.lock()
        defer { connectionLock.unlock() }

        guard connection == nil else {
            throw PostgresError.connectionAlreadyOpen
        }

        var connectionString = "host='\(host)' port='\(port)' user='\(username)'' dbname='\(databaseName)"

        if let pw = password {
            connectionString += " password='\(pw)'"
        }

        connection = PQconnectdb(connectionString)
        let status = PQstatus(connection!)

        if status != CONNECTION_OK {
            let error = String(validatingUTF8: PQerrorMessage(connection!))
            PQfinish(connection!)
            connection = nil
            throw PostgresError.couldntConnect(error)
        }

        do {
            try executeQuery("SET datestyle TO ISO, MDY")
        } catch let error {
            PQfinish(connection!)
            connection = nil
            throw error
        }
    }


    public func executeQuery(query: String) throws -> PGResult {
        connectionLock.lock()
        defer { connectionLock.unlock() }

        guard let conn = connection else {
            throw PostgresError.invalidConnection
        }

        let res = PQexec(conn, query)
        return PGResult(result: res)
    }

    public func disconnect() throws {
        connectionLock.lock()
        defer { connectionLock.unlock() }
        guard let conn = connection else { throw PostgresError.connectionNotOpen }
        PQfinish(conn)
        connection = nil
    }
}


public enum PostgresError: ErrorProtocol {
    case connectionAlreadyOpen
    case couldntConnect(String?)
    case invalidConnection
    case incorrectResult
    case connectionNotOpen
}
