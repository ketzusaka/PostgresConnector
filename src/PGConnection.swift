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

/**
 A connection to a Postgres database.
 */
public class PGConnection {
    /// The host to connect to
    public let host: String

    /// The username to use for the connection
    public let username: String

    /// The port to connect to
    public let port: Int

    /// The database to connect to
    public let databaseName: String

    private let connectionLock = NSLock()

    public init(host: String = "localhost", username: String, port: Int = 5432, databaseName: String) {
        self.host = host
        self.username = username
        self.port = port
        self.databaseName = databaseName
    }

    private var connection: OpaquePointer?

    /**
     Connects to the database.
     
     - parameter    password:   An optional password to connect with.
     - throws:      `PostgresError.couldNotConnect` if the connection failed.
                    `PostgresError.couldNotSetDateStyle` if we couldn't set our required date style
    */
    public func connect(usingPassword password: String? = nil) throws {
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
            throw PostgresError.couldNotConnect(error)
        }

        do {
            if try execute(query: "SET datestyle TO ISO, MDY").status == PGResultStatus.successful {
                throw PostgresError.couldNotSetDateStyle
            }
        } catch let error {
            PQfinish(connection!)
            connection = nil
            throw error
        }
    }

    /**
     Execute a query string.
     
     - parameter    query:  The query string to execute
     - returns:     A `PGResult` representing the query
     - throws:      `PostgresError.invalidConnection` if there isn't a connection.
     */
    public func execute(query query: String) throws -> PGResult {
        connectionLock.lock()
        defer { connectionLock.unlock() }

        guard let conn = connection else {
            throw PostgresError.invalidConnection
        }

        let res = PQexec(conn, query)
        return PGResult(result: res)
    }

    /**
     Disconnect from the postgres database.
     
     - throws:  `PostgresError.connectionNotOpen` if there isn't an active connection
    */
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
    case couldNotConnect(String?)
    case couldNotSetDateStyle
    case invalidConnection
    case incorrectResult
    case connectionNotOpen
}
