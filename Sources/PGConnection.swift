//
//  PGConnection.swift
//  PostgresConnector
//
//  Created by James Richard on 2/9/16.
//
//

#if os(Linux)
    import Glibc
    import CPostgreSQLLinux
#else
    import Darwin
    import CPostgreSQLMac
#endif

import Foundation
import String

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

    private let connectionLock = Lock()

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

        var connectionString = "host='\(host)' port='\(port)' user='\(username)' dbname='\(databaseName)'"

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
            let status = try execute(query: "SET datestyle TO ISO, MDY", lock: false).status
            if status != PGResultStatus.successful {
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
    public func execute(query: String) throws -> PGResult {
        return try execute(query: query, lock: true)
    }

    /**
     Execute a query formattable query string. This will escape occurrances of ' with
     \' to prevent injection attacks.

     - parameter    query:  The format query string to execute
     - parameter    values: The values to substitute in.
     - returns:     A `PGResult` representing the query
     - throws:      `PostgresError.invalidConnection` if there isn't a connection.
     */
    public func execute(query: String, values: String...) throws -> PGResult {
        let safeValues = values.map { $0.replacingOccurrences(of: "'", with: "\\'") }

        return try execute(query: String(query: query, arguments: safeValues))
    }

    private func execute(query: String, lock: Bool) throws -> PGResult {
        if lock {
            connectionLock.lock()
        }

        defer {
            if lock {
                connectionLock.unlock()
            }
        }

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
    case invalidQueryString(String)
}

extension String {
    init(query: String, arguments: [String]) throws {
        let parts = query.split(byString: "%@")
        guard parts.count == arguments.count + 1 else {
            throw PostgresError.invalidQueryString("The number of arguments (\(arguments.count)) does not match the number of parameters (\(parts.count - 1))")
        }

        guard parts.count > 1 else {
            self = parts[0]
            return
        }

        var builtString = ""

        for (index, part) in parts.enumerated() {
            builtString.append(part)
            if index != parts.index(parts.endIndex, offsetBy: -1) {
                builtString.append(arguments[index])
            }
        }
        
        self = builtString
    }
    
}
