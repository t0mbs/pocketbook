//
//  File.swift
//  PocketBook
//
//  Created by Nathanael Tombs on 2015-08-06.
//  Copyright (c) 2015 Nathanael Fournier-Tombs. All rights reserved.
//

import Foundation
import CoreData

class Master {
    static let sharedInstance = Master()
    let managedContext: NSManagedObjectContext
    let userPreferences = UserPreferenceModel.singleInstance
    
    func setNewBook(id: Int) {
        setNewBook("\(id)")
    }
    
    func setNewBook(id: String) {
        userPreferences[.currentBook] = id
    }
    
    let bookEntityName = "Book"
    let chapEntityName = "Chapter"
    
    let bookEntity: NSEntityDescription
    let chapEntity: NSEntityDescription
    let backEnd: JSONBackEnd = JSONBackEnd.singleInstance
    
    init() {
        managedContext = AppDelegate.sharedInstance.managedObjectContext!
        bookEntity =  NSEntityDescription.entityForName(bookEntityName,
            inManagedObjectContext:
            managedContext)!
        chapEntity = NSEntityDescription.entityForName(chapEntityName,
            inManagedObjectContext:
            managedContext)!
    }
    
}