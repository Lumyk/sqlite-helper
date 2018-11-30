//
//  StorableConfig.swift
//  SQLite
//
//  Created by Evgeny Kalashnikov on 18.05.2018.
//

import Foundation
import apollo_mapper

/// clearBeforeSave — defailt false
/// replaceIfExist — default true
/// transactionSplitter — default .one
/// storeOnly — default false
public class StorableConfig {
    public let type: Storable.Type
    public var clearBeforeSave: Bool
    public let replaceIfExist: Bool
    public let transactionSplitter: MapperStorageTransactionSplitter
    public let storeOnly: Bool
    
    public init(type: Storable.Type, clearBeforeSave: Bool = false, replaceIfExist: Bool = true, transactionSplitter: MapperStorageTransactionSplitter = .one, storeOnly: Bool = false) {
        self.type = type
        self.clearBeforeSave = clearBeforeSave
        self.replaceIfExist = replaceIfExist
        self.transactionSplitter = transactionSplitter
        self.storeOnly = storeOnly
    }
}
