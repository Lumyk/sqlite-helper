import SQLite
import apollo_mapper
@testable import sqlite_helper


class Machine: Savable {
    var id: Int
    var registrationNumber: String?
    var machineGroupId: Int?
    var name: String?

    // Mappable
    required init(mapper: Mapper) throws {
        self.id = try mapper.value(key: "id", transformType: TransformTypes.stringToInt)
        self.registrationNumber = try mapper.value(key: "registration_number")
        self.machineGroupId = try mapper.value(key: "machine_group_id", transformOptionalType: TransformTypes.stringToInt)
        self.name = try mapper.value(key: "name")
    }

    // Stored
    static let id = Expression<Int>("id")
    static let registrationNumber = Expression<String?>("registrationNumber")
    static let machineGroupId = Expression<Int?>("machineGroupId")
    static let name = Expression<String?>("name")

    required init(row: Row) throws {
        let Type = type(of: self)
        do {
            self.id = try row.get(Type.id)
            self.registrationNumber = try row.get(Type.registrationNumber)
            self.machineGroupId = try row.get(Type.machineGroupId)
            self.name = try row.get(Type.name)
        } catch {
            do {
                let t = Type.table
                self.id = try row.get(t[Type.id])
                self.registrationNumber = try row.get(t[Type.registrationNumber])
                self.machineGroupId = try row.get(t[Type.machineGroupId])
                self.name = try row.get(t[Type.name])
            } catch let error {
                throw error
            }
        }
    }

    static func tableBuilder(tableBuilder: TableBuilder) {
        tableBuilder.column(id, primaryKey: true)
        tableBuilder.column(registrationNumber)
        tableBuilder.column(machineGroupId)
        tableBuilder.column(name)
    }

    func insertMapper() -> [Setter] {
        let Type = type(of: self)
        return [
            Type.id <- self.id,
            Type.registrationNumber <- self.registrationNumber,
            Type.machineGroupId <- self.machineGroupId,
            Type.name <- self.name
        ]
    }

    static func insertMapper(mapper: Mapper) throws -> [Setter] {
        return [
            id <- try mapper.value(key: "id", transformType: TransformTypes.stringToInt, type: Int.self),
            registrationNumber <- try mapper.value(key: "registration_number", type: String?.self),
            machineGroupId <- try mapper.value(key: "machine_group_id", transformOptionalType: TransformTypes.stringToInt, type: Int?.self),
            name <- try mapper.value(key: "name", type: String?.self)
        ]
    }

    func updateMapper() -> [Setter] {
        let Type = type(of: self)
        return [
            Type.registrationNumber <- self.registrationNumber,
            Type.machineGroupId <- self.machineGroupId,
            Type.name <- self.name
        ]
    }
}


class MachineBroken: Savable {
    
    required init(mapper: Mapper) throws {
        
    }
    
    init() {
        
    }
    
    required init(row: Row) throws {
        throw MappingError.differentTypes
    }
    
    static func tableBuilder(tableBuilder: TableBuilder) {
        
    }
    
    func insertMapper() -> [Setter] {
        return []
    }
    
    static func insertMapper(mapper: Mapper) throws -> [Setter] {
        throw MappingError.differentTypes
    }
}
