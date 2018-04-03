import XCTest
import SQLite
import apollo_mapper
@testable import sqlite_helper


class sqlite_helperTests: XCTestCase {
    
    func createConnectionAndTable() -> Connection {
        let connection = try! Connection(Connection.Location.inMemory, readonly: false)
        try! Machine.create(connection: connection, ifNotExists: true)
        return connection
    }
    
    func createConnectionAndTableAndInsert() -> (connection: Connection, machine: Machine) {
        let connection = self.createConnectionAndTable()
        let machine = try! Machine(snapshot: ["id" : "1", "registration_number" : "23233", "name" : "My Car", "machine_group_id" : nil])
        try! Machine.insert(connection: connection, object: machine, replace: true)
        return (connection: connection, machine: machine)
    }
    
    func testEncodeDecode() {
        let data = try? Machine.encode(["value" : "10"])
        let decoded : [String : String]? = try! Machine.decode(data: data)
        XCTAssertEqual(decoded!, ["value" : "10"])
        
        let decoded1 : String? = try! Machine.decode(data: nil)
        XCTAssertEqual(decoded1, nil)
    }
    
    func testTable() {
        XCTAssertEqual(Machine.table.asSQL(), Table("machines").asSQL())
    }
    
    func testCreateTable() {
        let connection = self.createConnectionAndTable()
        let data = try? Machine.select(connection: connection)
        XCTAssert(data != nil)
    }
    
    func testInsertObject() {
        let connection = self.createConnectionAndTable()
        let machine = try! Machine(snapshot: ["id" : "1", "registration_number" : "23233", "name" : "My Car", "machine_group_id" : nil])
        try! Machine.insert(connection: connection, object: machine, replace: false)
        let registrationNumber = try! Machine.select(connection: connection).first?.registrationNumber
        XCTAssertEqual(registrationNumber, "23233")

        machine.registrationNumber = "123"
        try! Machine.insert(connection: connection, object: machine, replace: true)
        let registrationNumber1 = try! Machine.select(connection: connection).first?.registrationNumber
        XCTAssertEqual(registrationNumber1, "123")
    }
    
    func testInsertMapper() {
        let connection = self.createConnectionAndTable()
        let mapper = Mapper(snapshot: ["id" : "3", "registration_number" : "23233", "name" : "My Car", "machine_group_id" : nil])
        try! Machine.insert(connection: connection, mapper: mapper, replace: false)
        let registrationNumber = try! Machine.select(connection: connection).first?.registrationNumber
        XCTAssertEqual(registrationNumber, "23233")
        
        let mapper1 = Mapper(snapshot: ["id" : "3", "registration_number" : "123", "name" : "My Car", "machine_group_id" : nil])
        try! Machine.insert(connection: connection, mapper: mapper1, replace: true)
        let registrationNumber1 = try! Machine.select(connection: connection).first?.registrationNumber
        XCTAssertEqual(registrationNumber1, "123")
    }
    
    func testUpdate() {
        let data = self.createConnectionAndTableAndInsert()
        
        let machine = try! Machine.select(connection: data.connection).first!
        machine.registrationNumber = "1234"
        do {
            try machine.update(connection: data.connection)
        } catch {
            XCTFail()
        }
        
        let registrationNumber = try! Machine.select(connection: data.connection).first?.registrationNumber
        XCTAssertEqual(registrationNumber, "1234")
        
        do {
            try MachineBroken().update(connection: data.connection)
            XCTFail()
        } catch {
            XCTAssert(true)
        }
    }
    
    func testSelectWithFilter() {
        let data = self.createConnectionAndTableAndInsert()
        let connection = data.connection
        
        let machine = try! Machine.select(connection: connection, filter: Machine.id == 1).first
        XCTAssertEqual(machine?.registrationNumber, "23233")
        
        let machine1 = try! Machine.select(connection: connection, filter: Machine.machineGroupId == nil).first
        XCTAssertEqual(machine1?.registrationNumber, "23233")
    }
    
    func testSelectWithQuery() {
        let data = self.createConnectionAndTableAndInsert()
        let connection = data.connection
        
        do {
            _ = try Machine.select(connection: connection, query: Machine.table.join(Machine.table, on: Machine.id == Machine.id))
            XCTFail()
        } catch {
            XCTAssert(true)
        }
    }
    
    func testSavableMap() {
        let connection = self.createConnectionAndTable()
        do {
            let machine = try Machine.map(connection: connection, snapshots: [["id" : "3", "registration_number" : "23233", "name" : "My Car", "machine_group_id" : nil]]).first
            XCTAssertEqual(machine?.registrationNumber, "23233")
        } catch {
            XCTFail()
        }
    }
    
    func testStorege() {
        let connection = self.createConnectionAndTable()
        
        let storage = Storege(connection: connection, types: [Machine.self])
        let mapper = Mapper(snapshot: ["id" : "3", "registration_number" : "23233", "name" : "My Car", "machine_group_id" : nil])
        do {
            try storage.save(object: try Machine(mapper: mapper))
            XCTAssert(true)
        } catch {
            XCTFail()
        }
        
        do {
            try storage.save(object: mapper, objectType: Machine.self)
            XCTAssert(true)
        } catch {
            XCTFail()
        }
    }
    
    func testStoregeError() {
        let data = self.createConnectionAndTableAndInsert()
        let connection = data.connection

        let storage = Storege(connection: connection, types: MachineBroken.self)
        do {
            try storage.save(object: data.machine)
            XCTFail()
        } catch {
            XCTAssert(true)
        }
        
        do {
            try storage.save(object: Mapper(snapshot: [:]), objectType: Machine.self)
            XCTFail()
        } catch {
            XCTAssert(true)
        }
    }
    
    static var allTests = [
        ("testEncodeDecode", testEncodeDecode),
        ("testTable", testTable),
        ("testCreateTable", testCreateTable),
        ("testInsertObject", testInsertObject),
        ("testInsertMapper", testInsertMapper),
        ("testUpdate", testUpdate),
        ("testSelectWithFilter", testSelectWithFilter),
        ("testSelectWithQuery", testSelectWithQuery),
        ("testSavableMap", testSavableMap),
        ("testStorege", testStorege),
        ("testStoregeError", testStoregeError),
    ]
}
