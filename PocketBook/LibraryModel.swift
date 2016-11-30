//
//  LibraryModel
//  PocketBook
//
//  Created by Nathanael Tombs on 2015-08-05.
//  Copyright (c) 2015 Nathanael Fournier-Tombs. All rights reserved.
//

import Foundation

struct BookListing {
    var author: String
    var id: String
    var title: String
    
    init (author: String, id: String, title: String) {
        self.author = author
        self.id = id
        self.title = title
    }
}

class LibraryModel {
    let library = Library.sharedInstance
    let master = Master.sharedInstance
    var bookList: [ BookListing ] = [BookListing]()
    
    init () {
        master.backEnd.getBookList() {
            [weak parent = self] (data, error) in
            dispatch_sync(dispatch_get_main_queue()) {
                if let results = data {
                    for result in results {
                        if let author = result["author"] as? String, id = result["id"] as? String, title = result["title"] as? String {
                            self.bookList.append(BookListing(author: author, id: id, title: title))
                        }
                    }
                }
            }
        }
    }
}