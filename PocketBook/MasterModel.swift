//
//  MasterModel.swift
//  PocketBook
//
//  Created by Nathanael Tombs on 2015-08-05.
//  Copyright (c) 2015 Nathanael Fournier-Tombs. All rights reserved.
//

import Foundation
import CoreData

class MasterModel {
    let backEnd = JSONBackEnd.singleInstance
    let userPreferences = UserPreferenceModel.singleInstance
    
    func setNewBook(id: Int) {
        setNewBook("\(id)")
    }
    
    func setNewBook(id: String) {
        userPreferences[.currentBook] = id
    }
}