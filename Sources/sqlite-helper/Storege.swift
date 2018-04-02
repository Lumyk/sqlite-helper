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

class Storege: MapperStorage {
    
    func save<T: Mappable>(object: Mapper, objectType: T.Type) throws {
        for Type in self.types {
            if objectType == Type {
                try Type.insert(connection: self.connection, mapper: object, replace: true)
                return
            }
        }
        throw MappingError.notRegistered
    }
    
    func save<T: Mappable>(object: T) throws {
        for Type in self.types where type(of: object) == Type {
            if let object = object as? Storable {
                try Type.insert(connection: self.connection, object: object, replace: true)
                return
            }
        }
        throw MappingError.notRegistered
    }

    let connection: Connection
    let types: [Storable.Type]
    
    init(connection: Connection, types: Storable.Type...) {
        self.connection = connection
        self.types = types
    }
}
