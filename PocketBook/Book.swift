//
//  Book.swift
//  PocketBook
//
//  Created by Nathanael Tombs on 2015-08-05.
//  Copyright (c) 2015 Nathanael Fournier-Tombs. All rights reserved.
//

import Foundation
import CoreData

enum BookKey {
    case title
    case author
    case coverUrl
    case id
    case descr
    case currentChapter
    case chapterCount
}

func getBookKeyValue (key: BookKey)->String? {
    switch (key) {
    case .title:
        return "title"
    case .author:
        return "author"
    case .coverUrl:
        return "cover_url"
    case .id:
        return "id"
    case .descr:
        return "descr"
    case .currentChapter:
        return "current_chapter"
    case .chapterCount:
        return "chapter_count"
    default:
        return nil
    }
}

struct BookMsgs {
    static let notificationName = "Book"
    static let notificationEventKey = "Book Message Key"
    static let modelChangeDidSucceed = "Book Change Succeeded"
    static let modelChangeDidFail = "BookChange Failed"
}

/*
Initially had Book as an extension of NSManagedObject
Turns out NSManagedObject objects cannot have a subscript
Or else you get a very nondescript EXC_BAD_ACCESS error
*/

class Book {
    
    private var secretBook: NSManagedObject
    private var chapters = [Int: Chapter]()
    private var master: Master = Master.sharedInstance
    var observer: NSObjectProtocol?
    
    subscript (key: BookKey) -> String? {
        get {
            if let bookKey = getBookKeyValue(key) {
                return secretBook.valueForKey(bookKey) as? String
            }
            return nil
        }
        set (newValue) {
            if let bookKey = getBookKeyValue(key) {
                secretBook.setValue(newValue, forKey: bookKey)
            }
        }
    }
    
    var id: Int? {
        if let idStr = self[.id], id = idStr.toInt() {
            return id
        }
        return nil
    }
    
    required init(id: String, chapterId: Int = 1) {
        Util.log("Beginning book \(id) initialization")
        
        // Try to fetch the book from memory
        let fetchRequest = NSFetchRequest(entityName:master.bookEntityName)
        fetchRequest.predicate = NSPredicate(format:"\(getBookKeyValue(.id)!) == \(id)")
        
        var error: NSError?
        
        let fetchedResults =
        master.managedContext.executeFetchRequest(fetchRequest,
            error: &error) as? [NSManagedObject]

        if fetchedResults != nil && fetchedResults!.count > 0 {
            // Fetch the book from memory
            Util.log("Book found in memory")
            secretBook = fetchedResults![0]
            self.notifyObservers(success: true)
        } else {
            // Fetch the book via an AJAX request
            secretBook = NSManagedObject(entity: master.bookEntity,
                insertIntoManagedObjectContext: master.managedContext)
            
            master.backEnd.getBookDetails(id.toInt()!) {
                [weak parent = self] (data, error) in
                dispatch_sync(dispatch_get_main_queue(), {
                    if let results = data {
                        var result = results[0]
                        if let author = result["author"] as? String, id = result["id"] as? String, title = result["title"] as? String, descr = result["description"] as? String, coverUrl = result["cover_url"] as? String, chapterCount = result["chapter_count"] as? String {
                            Util.log("Book detail results validated")
                            self[.id]             = id
                            self[.title]          = title
                            self[.author]         = author
                            self[.descr]          = descr
                            self[.coverUrl]       = coverUrl
                            self[.chapterCount]   = chapterCount
                            self[.currentChapter] = String(chapterId)
                        
                            self.saveData()
                            self.notifyObservers(success: true)
                            Util.log("Book loaded from server")
                        } else {
                            Util.log("Book detail results not validated")
                        }
                    } else {
                        Util.log("No results received from the server")
                    }
                });
            }
        }
        if let storedChapterId = self[.currentChapter] {
            self.chapters[storedChapterId.toInt()!] = Chapter(bookId: id, chapterId: storedChapterId)
        } else {
            self.chapters[chapterId] = Chapter(bookId: id, chapterId: String(chapterId))
            self[.currentChapter] = String(chapterId)
            saveData()
        }
        startChapterListener()
    }
    
    func loadChapter(chapterId: Int, save: Bool = false, notify: Bool = false) {
        Util.log("Getting chapter \(chapterId)")

        // Attempt to fetch chapter from app memory
        if let existingChapter = self.chapters[chapterId] {
            if save {
                self[.currentChapter] = "\(chapterId)"
                self.saveData()
            }
            self.notifyObservers(success: true)
        } else {
            if let bookId = self[.id] {
                let chapter = Chapter(bookId: bookId, chapterId: String(chapterId))
                self.chapters[chapterId] = chapter
                if save {
                    self[.currentChapter] = "\(chapterId)"
                    self.saveData()
                }
                startChapterListener()
            }
        }
    }
    
    func getChapter(chapterId: Int) -> Chapter? {
        if let existingChapter = self.chapters[chapterId] {
            return existingChapter
        }
        return nil
    }
    
    
    func notifyObservers(#success: Bool) {
        Util.log("Book notifying \(success)")
        let message = success ? BookMsgs.modelChangeDidSucceed : BookMsgs.modelChangeDidFail
        let notification = NSNotification(
            name: BookMsgs.notificationName, object: self,
            userInfo: [ BookMsgs.notificationEventKey : message ])
        NSNotificationCenter.defaultCenter().postNotification(notification)
    }
    
    func startChapterListener() {
        let center = NSNotificationCenter.defaultCenter()
        let uiQueue = NSOperationQueue.mainQueue()
        if let currentChapter = self[.currentChapter], chapter = chapters[currentChapter.toInt()!] {
            observer = center.addObserverForName(ChapterMsgs.notificationName, object: chapter, queue: uiQueue) {
                (notification) in
                if let message = notification.userInfo?[ChapterMsgs.notificationEventKey] as? String {
                    self.handleNotification(message)
                }
                else {
                    assertionFailure("No message found in notification")
                }
            }
        }
    }
    
    func handleNotification(message: String) {
        Util.log("Chapter Detail View Controller handling message \(message)")
        switch message {
        case ChapterMsgs.modelChangeDidSucceed:
            notifyObservers(success: true)
        default:
            assertionFailure("Unexpected message: \(message)")
        }
    }
    
    func saveData() {
        Util.log("Saving book data")
        //Save data
        var error: NSError?
        if !self.master.managedContext.save(&error) {
            Util.log("Could not save \(error), \(error?.userInfo)")
        }
    }
}