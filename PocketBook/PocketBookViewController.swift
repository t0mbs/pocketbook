//
//  PocketBookViewController.swift
//  PocketBook
//
//  Created by Nathanael Tombs on 2015-07-23.
//  Copyright (c) 2015 Nathanael Fournier-Tombs. All rights reserved.
//

import UIKit

class PocketBookViewController: UIViewController {
    var model: PocketBookModel?
    
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var chapterLabel: UILabel!
    
    @IBOutlet weak var placeholder: UITextView!
    
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var prevButton: UIButton!
    var observer: NSObjectProtocol?
    
    @IBAction func nextChapterClick(sender: UIButton) {
        if let m = model {
            if m.hasNextChapter
            {
                m.currentChapterId++
            }
            displayNextPrevButtons(m.hasPrevChapter, hasNext: m.hasNextChapter)
        }
    }
    
    @IBAction func prevChapterClick(sender: UIButton) {
        if let m = model {
            if m.hasPrevChapter {
                m.currentChapterId--
            }
            displayNextPrevButtons(m.hasPrevChapter, hasNext: m.hasNextChapter)
        }
    }
    
    func displayNextPrevButtons(hasPrev: Bool, hasNext: Bool) {
        if hasNext {
            nextButton.hidden = false
        } else {
            nextButton.hidden = true
        }
        
        if hasPrev {
            prevButton.hidden = false
        } else {
            prevButton.hidden = true
        }
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        model = PocketBookModel()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        updateGraphicalView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let m = model {
            displayNextPrevButtons(m.hasPrevChapter, hasNext: m.hasNextChapter)
        }
        startModelListener()
    }
    
    func updateGraphicalView() {
        Util.log("Updating Pocket Book View Controller Visuals")
        if let m = model, chapter = m.getChapter(m.currentChapterId) {
            if let b = m.book, title = b[.title] {
                titleLabel.text = title
            }
            
            if let name = chapter[.name], content = chapter[.content] {
                Util.log("Model and Chapter successfully unwraped")
                placeholder.text = content
                chapterLabel.text = name
            }
            self.view.setNeedsDisplay()
        } else {
            Util.log("Failed to unwrap Model and Chapter")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

