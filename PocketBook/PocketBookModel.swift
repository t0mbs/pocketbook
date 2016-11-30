//
//  PocketBook.swift
//  PocketBook
//
//  Created by Nathanael Tombs on 2015-08-05.
//  Copyright (c) 2015 Nathanael Fournier-Tombs. All rights reserved.
//

import Foundation

class PocketBookModel {
    let library = Library.sharedInstance
    let master = Master.sharedInstance
    
    weak var book: Book?
    
    var chapterCount: Int {
        if let b = book, chap = b[.chapterCount] {
            return chap.toInt()!
        }
        return 100
    }
    
    var currentChapterId: Int = 1 {
        didSet {
            updateChapter(currentChapterId)
        }
    }
    
    var currentBookId: String {
        get {
            if let b = book, id = b[.id] {
                return id
            } else if let id = master.userPreferences[.currentBook] {
                return id
            }
            return "1"
        }
        set {
            master.userPreferences[.currentBook] = "\(currentBookId)"
        }
    }
    
    
    var hasNextChapter: Bool {
        return currentChapterId < chapterCount
    }
    var hasPrevChapter: Bool {
        return Int(currentChapterId) > 1
    }
    
    init () {
        book = library.getBook(currentBookId)
        if let predefinedChapter = book![.currentChapter] {
            currentChapterId = predefinedChapter.toInt()!
        } else {
            self.currentChapterId = 1
        }
        //didSet did not kick in yet
        updateChapter(currentChapterId)
    }
    
    func getChapter(chapterId: Int) -> Chapter? {
        if let b = book, c = b.getChapter(chapterId) {
            return c
        }
        return nil
    }
    
    func updateChapter(currentChapterId: Int) {
        if let b = book {
            b.loadChapter(currentChapterId, save: true, notify: true)
            if hasNextChapter {
                b.loadChapter(currentChapterId+1)
            }
        }
    }
    
    func notifyUser(#title: String, message: String) {
        println(message)
    }
}