//
//  StorableConfig.swift
//  SQLite
//
//  Created by Evgeny Kalashnikov on 18.05.2018.
//

import Foundation
import apollo_mapper

public struct StorableConfig {
    public let type: Storable.Type
    public let clearBeforeSave: Bool
    public let replaceIfExist: Bool
    public let transactionSplitter: MapperStorageTransactionSplitter
    
    public init(type: Storable.Type, clearBeforeSave: Bool = false, replaceIfExist: Bool = true, transactionSplitter: MapperStorageTransactionSplitter = .one) {
        self.type = type
        self.clearBeforeSave = clearBeforeSave
        self.replaceIfExist = replaceIfExist
        self.transactionSplitter = transactionSplitter
    }
}
