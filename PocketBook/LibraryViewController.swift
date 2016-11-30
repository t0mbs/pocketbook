//
//  LibraryViewController.swift
//  PocketBook
//
//  Created by Nathanael Tombs on 2015-07-23.
//  Copyright (c) 2015 Nathanael Fournier-Tombs. All rights reserved.
//

import UIKit

struct Identifiers {
    static let bookDetailSegue = "book detail segue"
    static let bookDetailCell = "book detail cell"
    static let maxBook = 5
}

class BookDetailModelCollection {
    var books = [String: BookDetailModel?]()
}

/*
Since book IDs will not necessarily be sequential I need an array of cellIds => real bookIds
*/

class LibraryViewController: UITableViewController {
    var model: LibraryModel?
    var bookDetailModelCollection = BookDetailModelCollection()
    var cellToId = [Int: String]()

    var mostRecentMoreInfo: String? {
        didSet {
            tableView.reloadData()
        }
    }
    
    required init!(coder aDecoder: NSCoder!) {
        let app = UIApplication.sharedApplication().delegate!  as! AppDelegate
        model = LibraryModel()
        var m = model!
        
        for book in m.bookList {
            bookDetailModelCollection.books[book.id] = nil
        }
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return count(model!.bookList)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.bookDetailCell, forIndexPath: indexPath) as! UITableViewCell
   
        cell.textLabel!.text = model!.bookList[indexPath.row].title
        self.cellToId[indexPath.row] = model!.bookList[indexPath.row].id
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier ?? "MISSING" {
        case Identifiers.bookDetailSegue:
            if let indexPath = tableView.indexPathForSelectedRow() {

                var bookId = cellToId[indexPath.row]!
                let m = model!
                
                Util.log("Preparing for segue for book id \(bookId)")
                if let bookDetail = segue.destinationViewController as? BookDetailViewController {
                    if let modelAtIndex = bookDetailModelCollection.books[bookId], detailModel = modelAtIndex {
                        Util.log("Model already exists in library of books")
                        bookDetail.model = detailModel
                    } else {
                        Util.log("Model did not already exists in library of books")
                        let book = m.library.getBook(bookId)
                        var detailModel = BookDetailModel(book: book)
                        bookDetailModelCollection.books[bookId] = detailModel
                        bookDetail.model = detailModel
                    }
                }
                else {
                    assertionFailure("destination of segue was not a Book Detail VC!")
                }
            }
            else {
                assertionFailure("prepareForSegue called when no row selected")
            }
        default:
            assertionFailure("unknown segue ID \(segue.identifier)")
        }
    }
}
