//
//  Library.swift
//  PocketBook
//
//  Created by Nathanael Tombs on 2015-08-06.
//  Copyright (c) 2015 Nathanael Fournier-Tombs. All rights reserved.
//

import Foundation

/*
Simple container of Book objects
*/

class Library {
    static let sharedInstance = Library()
    // for book storage
    var books = [String: Book]()

    
    func storeBook(id:String, book: Book) {
        books[id] = book
    }
    
    func getBook(id: String) -> Book {
        if let book = books[id] {
            return book
        } else {
            var book = Book(id: id)
            storeBook(id, book: book)
            return book
        }
    }
}