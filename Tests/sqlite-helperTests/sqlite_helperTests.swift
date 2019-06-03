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
        let data = try? Machine.encodeToJSON(["value" : "10"])
        let decoded : [String : String]? = try! Machine.decodeFromJSON(data: data)
        XCTAssertEqual(decoded!, ["value" : "10"])
        
        let decoded1 : String? = try! Machine.decodeFromJSON(data: nil)
        XCTAssertEqual(decoded1, nil)
    }
    
    func testEncodeDecode2() {
        let data = Machine.encode(["value" : "10"])
        let decoded : [String : String]? = Machine.decode(data: data)
        XCTAssertEqual(decoded!, ["value" : "10"])
        
        let decoded1 : String? = Machine.decode(data: nil)
        XCTAssertEqual(decoded1, nil)
        XCTAssertEqual(Machine.encode(nil), nil)

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
    
    func testTransactions() {
        let data = self.createConnectionAndTableAndInsert()
        let connection = data.connection
        let storage = Storege(connection: connection, configurations: StorableConfig(type:  MachineBroken.self, transactionSplitter: .split(by: 23)))
        switch storage.configurations.first!.transactionSplitter {
        case .split(by: 23):
            XCTAssert(true)
        default:
            XCTFail("testTransactions error 1")
        }
        
        do {
            try storage.transaction {
                throw MappingError.optional
            }
            XCTFail("testTransactions error 2")
        } catch let error as MappingError {
            switch error {
            case .optional:
                XCTAssert(true)
            default:
                XCTFail("testTransactions error 3")
            }
        } catch {
            XCTFail("testTransactions error 4")
        }
    }
    
    func testLast() {
        let data = self.createConnectionAndTableAndInsert()
        let connection = data.connection
        let storage = Storege(connection: connection, types: Machine.self)
        do {
            _ = try storage.last(Machine.self, column: Machine.registrationNumber)
            XCTAssert(true)
        } catch let error {
            XCTFail("testLast error 1 \(error)")
        }
        
        do {
            _ = try storage.last(MachineBroken.self, column: Machine.registrationNumber)
            XCTFail("testLast error 2")
        } catch {
            XCTAssert(true)
        }
    }
    
    func testConfig() {
        let config = Machine.config
        XCTAssert(config.type == Machine.self && config.clearBeforeSave == false && config.replaceIfExist == true, "testConfig error")
    }
    
    func testClearTable() {
        let data = createConnectionAndTableAndInsert()
        let snapshot = ["id" : "2", "registration_number" : "23233", "name" : "My Car", "machine_group_id" : nil]
        let storage = Storege(connection: data.connection, configurations: [StorableConfig(type: Machine.self, clearBeforeSave: true)])
        
        do {
            try Mapper.mapToStorage(Machine.self, snapshots: [snapshot], storage: storage)
            let count = try Machine.select(connection: data.connection).count
            if count == 1 {
                XCTAssert(true)
            } else {
                XCTFail("testClearTable error 1 count - \(count)")
            }
        } catch {
            XCTFail("testClearTable error 2")
        }
    }
    
    func testClearIds() {
        let data = createConnectionAndTableAndInsert()
        let storage = Storege(connection: data.connection, configurations: StorableConfig(type: Machine.self))
        
        do {
            try! storage.clearEmptyId(for: Machine.self, ids: [0])
            let count = try Machine.select(connection: data.connection).count
            if count == 0 {
                XCTAssert(true)
            } else {
                XCTFail("testClearIds error count - \(count)")
            }
        } catch {
            XCTFail("testClearIds error 2")
        }
    }
    
    func testDelete1() {
        let data = createConnectionAndTableAndInsert()
        do {
            let d = try Machine.delete(connection: data.connection, query: Machine.table)
            let count = try Machine.select(connection: data.connection).count
            if count == 0, d == 1 {
                XCTAssert(true)
            } else {
                XCTFail("testDelete2 error count - \(count)")
            }
        } catch {
            XCTFail("testDelete2 error 2")
        }
    }
    
    func testDelete2() {
        let data = createConnectionAndTableAndInsert()
        do {
            try Machine.delete(connection: data.connection, filter: Machine.id == 1)
            let count = try Machine.select(connection: data.connection).count
            if count == 0 {
                XCTAssert(true)
            } else {
                XCTFail("testDelete2 error count - \(count)")
            }
        } catch {
            XCTFail("testDelete2 error 2")
        }
    }
    
    func testDelete3() {
        let data = createConnectionAndTableAndInsert()
        do {
            try Machine.delete(connection: data.connection, filter: Machine.name == nil)
            let count = try Machine.select(connection: data.connection).count
            if count == 1 {
                XCTAssert(true)
            } else {
                XCTFail("testDelete2 error count - \(count)")
            }
        } catch {
            XCTFail("testDelete2 error 2")
        }
    }
    
    func testStorageGetConfig() {
        let connection = self.createConnectionAndTable()
        let snapshot = ["id" : "2", "registration_number" : "23233", "name" : "My Car", "machine_group_id" : nil]
        let storage = Storege(connection: connection, configurations: [StorableConfig(type: MachineBroken.self, clearBeforeSave: true)])
        
        do {
            try Mapper.mapToStorage(Machine.self, snapshots: [snapshot], storage: storage)
            XCTFail("testStorageGetConfig error 1")

        } catch {
            XCTAssert(true)
        }
        
        switch storage.transactionSplitter(for: MachineBroken.self) {
        case .one:
            XCTAssert(true)
        default:
            XCTFail("testStorageGetConfig error 2")
        }
        
        let storageBroken = Storege(connection: connection, configurations: [])
        switch storageBroken.transactionSplitter(for: MachineBroken.self) {
        case .one:
            XCTAssert(true)
        default:
            XCTFail("testStorageGetConfig error 3")
        }
        
        do {
            try storageBroken.save(object: Mapper(snapshot: snapshot), objectType: MachineBroken.self)
            XCTFail("testStorageGetConfig error 4")
            
        } catch {
            XCTAssert(true)
        }
    }
    
    func testSelect() {
        let connection = self.createConnectionAndTableAndInsert()
        do {
            let machines = try Machine.select(connection: connection.connection, filter: Machine.id < 10)
            XCTAssertEqual(machines.count, 1)
        } catch let error {
            XCTFail("\(#function) - \(error)")
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
        ("testTransactions", testTransactions),
        ("testLast", testLast),
        ("testConfig", testConfig),
        ("testClearTable", testClearTable),
        ("testStorageGetConfig", testStorageGetConfig),
        ("testSelect", testSelect)
    ]
}
