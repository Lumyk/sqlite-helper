//
//  Storable.swift
//  sqlite-helper
//
//  Created by Evgeny Kalashnikov on 30.03.2018.
//

import Foundation
import SQLite
import apollo_mapper

public typealias Savable = Storable & Mappable

public protocol Storable {
    init(row: Row) throws
    static func tableBuilder(tableBuilder: TableBuilder)
    func insertMapper() -> [Setter]
    static func insertMapper(mapper: Mapper) throws -> [Setter]
    /// must contains only not unique db fields (skip primary key)
    func updateMapper() -> [Setter]
}

public extension Storable {
    
    public static func encode<T: Encodable>(_ any: T?) throws -> Data {
        return try JSONEncoder().encode(any)
    }
    
    public static func decode<T: Decodable>(data: Data?) throws -> T? {
        if let data = data {
            return try? JSONDecoder().decode(T.self, from: data)
        }
        return nil
    }
    
    func updateMapper() -> [Setter] { return [] /* for optional protocoling */ }
    
    public static var table: Table {
        let name = String(describing: Self.self).lowercased() + "s"
        return Table(name)
    }
    
    public static func create(connection: Connection, ifNotExists: Bool = false) throws {
        try connection.run(self.table.create( ifNotExists: ifNotExists) { t in
            Self.tableBuilder(tableBuilder: t)
        })
    }
    
    public static func insert(connection: Connection, object: Storable, replace: Bool = false) throws {
        let mapper = object.insertMapper()
        let query = replace ? self.table.insert(or: .replace, mapper) : table.insert(mapper)
        try connection.run(query)
    }
    
    public static func insert(connection: Connection, mapper: Mapper, replace: Bool = false) throws {
        let mapper = try Self.insertMapper(mapper: mapper)
        let query = replace ? self.table.insert(or: .replace, mapper) : table.insert(mapper)
        try connection.run(query)
    }
    
    public func update(connection: Connection) throws {
        let setters = self.updateMapper()
        let query = Self.table.update(setters)
        do {
            try connection.run(query)
        } catch let error {
            throw error
        }
    }
    
    public static func select(connection: Connection, filter: Expression<Bool?>) throws -> [Self] {
        let filter = self.table.filter(filter)
        return try self.select(connection: connection, query: filter)
    }
    
    public static func select(connection: Connection, filter: Expression<Bool>) throws -> [Self] {
        let filter = self.table.filter(filter)
        return try self.select(connection: connection, query: filter)
    }
    
    public static func select(connection: Connection, query: SchemaType? = nil) throws -> [Self] {
        let objects = try connection.prepare(query ?? self.table)
        return try objects.map { try Self(row: $0) }
    }
}

public extension Storable where Self: Mappable {
    static func map(connection: Connection, snapshots: [[String : Any?]?]) throws -> [Self] {
        let storage = Storege(connection: connection, types: Self.self)
        return try Mapper.map(Self.self, snapshots: snapshots, storage: storage)
    }
}
