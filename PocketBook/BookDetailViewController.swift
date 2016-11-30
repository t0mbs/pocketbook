//
//  BookDetailViewController.swift
//  PocketBook
//
//  Created by Nathanael Tombs on 2015-07-23.
//  Copyright (c) 2015 Nathanael Fournier-Tombs. All rights reserved.
//

import UIKit

class BookDetailViewController: UIViewController {
    var model: BookDetailModel?
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var chapterLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    @IBAction func readButtonClick(sender: AnyObject) {
        if let m = model {
            m.setNewBook()
        }
        self.performSegueWithIdentifier("spreeder from book segue", sender: self)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var observer: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.startModelListener()
    }
    
    override func viewDidAppear(animated: Bool) {
        updateGraphicalView()
    }
    
    func updateGraphicalView() {
        if let m = model {
            if let title = m.book[.title], author = m.book[.author], descr = m.book[.descr], cover = m.book[.coverUrl] {
                titleLabel.text = title
                authorLabel.text = author
                descriptionLabel.text = descr
                
                let url = NSURL(string: cover)
                if let data = NSData(contentsOfURL: url!) {
                    imageView.image = UIImage(data: data)
                }
            }
        }
    }
    
    func startModelListener() {
        let center = NSNotificationCenter.defaultCenter()
        let uiQueue = NSOperationQueue.mainQueue()
        observer = center.addObserverForName(BookMsgs.notificationName, object: model?.book, queue: uiQueue) {
            (notification) in
            if let message = notification.userInfo?[BookMsgs.notificationEventKey] as? String {
                self.handleNotification(message)
            }
            else {
                assertionFailure("No message found in notification")
            }
        }
    }
    
    func handleNotification(message: String) {
        Util.log("Book Detail View Controller handling message \(message)")
        switch message {
        case BookMsgs.modelChangeDidSucceed:
            updateGraphicalView()
        default:
            assertionFailure("Unexpected message: \(message)")
        }
    }
}

