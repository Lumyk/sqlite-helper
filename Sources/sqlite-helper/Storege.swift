//
//  Storege.swift
//  sqlite-helper
//
//  Created by Evgeny Kalashnikov on 06.03.2018.
//  Copyright © 2018 Evgeny Kalashnikov. All rights reserved.
//

import Foundation
import SQLite
import apollo_mapper

public class Storege: MapperStorage {
    
    public func transactionSplitter() -> MapperStorageTransactionSplitter {
        return self.splitter
    }
    
    public func transaction(_ block: () throws -> Void) throws {
        try self.connection.transaction {
            try block()
        }
    }
    
    public func save<T: Mappable>(object: Mapper, objectType: T.Type) throws {
        for Type in self.types {
            if objectType == Type {
                try Type.insert(connection: self.connection, mapper: object, replace: true)
                return
            }
        }
        throw MappingError.notRegistered
    }
    
    public func save<T: Mappable>(object: T) throws {
        for Type in self.types where type(of: object) == Type {
            if let object = object as? Storable {
                try Type.insert(connection: self.connection, object: object, replace: true)
                return
            }
        }
        throw MappingError.notRegistered
    }
    
    public func select<T: Storable>(_ type: T.Type, query: SchemaType?) throws -> [T] {
        guard (self.types.contains { $0 == type }) else {
            throw MappingError.notRegistered
        }
        return try T.select(connection: self.connection, query: query)
    }
    
    public func last<T: Storable>(_ type: T.Type, column: Expressible) throws -> T? {
        return try self.select(type, query: T.table.order(column).limit(1)).first
    }
    
    public let connection: Connection
    let types: [Storable.Type]
    let splitter: MapperStorageTransactionSplitter
    
    public init(connection: Connection, types: [Storable.Type], splitter: MapperStorageTransactionSplitter = .one) {
        self.connection = connection
        self.types = types
        self.splitter = splitter
    }
    
    public init(connection: Connection, types: Storable.Type..., splitter: MapperStorageTransactionSplitter = .one) {
        self.connection = connection
        self.types = types
        self.splitter = splitter
    }
}
