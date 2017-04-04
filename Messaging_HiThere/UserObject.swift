//
//  UserObject.swift
//  hiThereMessaging
//
//  Created by Project on 5/3/16.
//  Copyright © 2016 iOSFinalProject. All rights reserved.
//


import Foundation
import JSQMessagesViewController

class UserObject: NSObject {
    var name: String!
    var profileImageUrl: String?
    var uniqueId: String!

    convenience init(name: String, profileImage: String?, uniqueId: String) {
        self.init()
        self.name = name
        self.profileImageUrl = ""

        if let image = profileImage {
            self.profileImageUrl = image
        }
        self.uniqueId = uniqueId
    }
}
