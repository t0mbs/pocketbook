//
//  Chapter.swift
//  PocketBook
//
//  Created by Nathanael Tombs on 2015-08-06.
//  Copyright (c) 2015 Nathanael Fournier-Tombs. All rights reserved.
//

import Foundation
import CoreData

enum ChapterKey {
    case bookId
    case id
    case content
    case name
}

func getChapterKey (key: ChapterKey)->String? {
    switch (key) {
    case .id:
        return "id"
    case .bookId:
        return "book_id"
    case .content:
        return "content"
    case .name:
        return "name"
    default:
        return nil
    }
}

struct ChapterMsgs {
    static let notificationName = "Chapter"
    static let notificationEventKey = "Chapter Message Key"
    static let modelChangeDidSucceed = "Chapter Change Succeeded"
    static let modelChangeDidFail = "ChapterChange Failed"
}

class Chapter {
    var secretChapter: NSManagedObject
    private var master: Master = Master.sharedInstance
    
    subscript (key: ChapterKey) -> String? {
        get {
            if let bookKey = getChapterKey(key) {
                return secretChapter.valueForKey(bookKey) as? String
            }
            return nil
        }
        set (newValue) {
            if let chapKey = getChapterKey(key) {
                secretChapter.setValue(newValue, forKey: chapKey)
            }
        }
    }
    
    init (bookId: String, chapterId: String) {
        Util.log("Beginning chapter \(chapterId)) initialization")
        
        // Try to fetch the book from memory
        let fetchRequest = NSFetchRequest(entityName:master.chapEntityName)
        fetchRequest.predicate = NSPredicate(format:"\(getChapterKey(.id)!) == \(chapterId) && \(getChapterKey(.bookId)!) == \(bookId)")
        
        var error: NSError?
        
        let fetchedResults =
        master.managedContext.executeFetchRequest(fetchRequest,
            error: &error) as? [NSManagedObject]
        
        if fetchedResults != nil && fetchedResults!.count > 0 {
            Util.log("Chapter found in memory")
            secretChapter = fetchedResults![0]
        } else {
            secretChapter = NSManagedObject(entity: master.chapEntity,
                insertIntoManagedObjectContext: master.managedContext)
            
            Util.log("Fetching chapter from server")
            self.master.backEnd.getChapter(bookId, chapterId: String(chapterId)) {
                [weak parent = self] (data, error) in
                if let results = data {
                    let result = results[0]
                    if let name = result["name"] as? String, content = result["contents"] as? String {
                        self[.name] = name
                        self[.bookId] = bookId
                        self[.content] = content
                        self[.id] = chapterId
                        
                        //Save data
                        var error: NSError?
                        if !self.master.managedContext.save(&error) {
                            println("Could not save \(error), \(error?.userInfo)")
                        }
                        Util.log("Chapter values set")
                        self.notifyObservers(success: true)
                    }
                } else {
                    assertionFailure("Data not returned by server")
                }
            }
        }
    }
    
    func notifyObservers(#success: Bool) {
        Util.log("Chapter notifying \(success)")
        let message = success ? ChapterMsgs.modelChangeDidSucceed : ChapterMsgs.modelChangeDidFail
        let notification = NSNotification(
            name: ChapterMsgs.notificationName, object: self,
            userInfo: [ ChapterMsgs.notificationEventKey : message ])
        NSNotificationCenter.defaultCenter().postNotification(notification)
    }
}
