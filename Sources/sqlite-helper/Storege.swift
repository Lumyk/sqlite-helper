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

public class Storege {
    
    public func select<T: Storable>(_ type: T.Type, query: SchemaType?) throws -> [T] {
        guard (self.configurations.contains { $0.type == type }) else {
            throw MappingError.notRegistered
        }
        return try T.select(connection: self.connection, query: query)
    }
    
    public func last<T: Storable>(_ type: T.Type, column: Expressible) throws -> T? {
        return try self.select(type, query: T.table.order(column).limit(1)).first
    }
    
    private func getConfig<T: Mappable>(type: T.Type) throws -> StorableConfig {
        for config in self.configurations where type == config.type {
            return config
        }
        throw MappingError.notRegistered
    }
    
    public let connection: Connection
    public let configurations: [StorableConfig]
    
    public init(connection: Connection, configurations: [StorableConfig]) {
        self.connection = connection
        self.configurations = configurations
    }
    
    public convenience init(connection: Connection, configurations: StorableConfig...) {
        self.init(connection: connection, configurations: configurations)
    }
    
    /// init with default 'StorableConfig' parameters
    public convenience init(connection: Connection, types: Storable.Type...) {
        self.init(connection: connection, types: types)
    }
    
    /// init with default 'StorableConfig' parameters
    public init(connection: Connection, types: [Storable.Type]) {
        self.connection = connection
        self.configurations = types.map({ StorableConfig(type: $0) })
    }
}

extension Storege: MapperStorage {
    
    public func storeOnly<T>(for objectType: T.Type) -> Bool where T : Mappable {
        guard let config = try? self.getConfig(type: objectType) else { return false }
        return config.storeOnly
    }
    
    public func transactionSplitter<T>(for objectType: T.Type) -> MapperStorageTransactionSplitter where T : Mappable {
        guard let config = try? self.getConfig(type: objectType) else { return .one }
        return config.transactionSplitter
    }
    
    public func transaction(_ block: () throws -> Void) throws {
        try self.connection.transaction {
            try block()
        }
    }
    
    public func save<T>(object: Mapper, objectType: T.Type) throws where T : Mappable {
        for config in self.configurations where objectType == config.type {
            try config.type.insert(connection: self.connection, mapper: object, replace: config.replaceIfExist)
            return
        }
        throw MappingError.notRegistered
    }
    
    public func save<T>(object: T) throws where T : Mappable {
        let config = try self.getConfig(type: type(of: object))
        if let object = object as? Storable {
            try config.type.insert(connection: self.connection, object: object, replace: config.replaceIfExist)
        }
    }
    
    public func clearTable<T>(for objectType: T.Type) throws where T : Mappable {
        let config = try self.getConfig(type: objectType)
        if config.clearBeforeSave {
            try config.type.clearTable(connection: self.connection)
            config.clearBeforeSave = false
        }
    }
    
    public func clearEmptyId<T>(for objectType: T.Type, ids: [Int]) throws where T : Mappable {
        let config = try self.getConfig(type: objectType)
        if ids.count != 0 {
            try config.type.delete(connection: self.connection, filter: !ids.contains(SQLite.Expression<Int>("id")))
        }
    }
}
