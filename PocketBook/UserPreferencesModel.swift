//
//  UserPreferencesModel.swift
//  PocketBook
//
//  Created by Nathanael Tombs on 2015-08-05.
//  Copyright (c) 2015 Nathanael Fournier-Tombs. All rights reserved.
//

import Foundation

enum UserPreferenceKeys {
    case currentBook
    case currentChapter
}

class UserPreferenceModel {
    static let singleInstance = UserPreferenceModel()
    let defaults = NSUserDefaults.standardUserDefaults()

    func userPreferenceKeys (key: UserPreferenceKeys) -> String {
        switch(key) {
        case .currentBook:
            return "speedreader_current_book"
        case .currentChapter:
            return "speedreader_current_chapter"
        }
    }
    
    subscript(index: UserPreferenceKeys) -> String? {
        get {
            var key = userPreferenceKeys(index)
            if let value = defaults.valueForKey(key) as? String {
                return value
            }
            return nil
        }
        set(newValue) {
            var key = userPreferenceKeys(index)
            defaults.setValue(newValue, forKey: key)
            defaults.synchronize()
        }
    }
}