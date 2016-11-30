//
//  BookDetailModel.swift
//  PocketBook
//
//  Created by Nathanael Tombs on 2015-08-05.
//  Copyright (c) 20	15 Nathanael Fournier-Tombs. All rights reserved.
//

import Foundation

class BookDetailModel {
    let book: Book
    let master = Master.sharedInstance

    init(book: Book) {
        self.book = book
    }
    
    func setNewBook() {
        if let bookId = book.id {
            master.setNewBook(bookId)
        }
    }
}