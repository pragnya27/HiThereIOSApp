//
//  FirebaseConnector.swift
//  hiThereMessaging
//
//  Created by Project on 5/3/16.
//  Copyright © 2016 iOSFinalProject. All rights reserved.
//

import Foundation
import Firebase
import JSQMessagesViewController

class FirebaseConnector: NSObject {
    // Use this class as Singleton
    static let sharedInstance = FirebaseConnector()

    // Our reference to Firebase
    var ref: Firebase!

    // Our current logged in user
    var currentUser: UserObject!
    
    var currentUser_ref: Firebase {
        let userID = NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String
        let currentUser = ref.childByAppendingPath("users").childByAppendingPath(userID)
        return currentUser!
    }

    override init() {
        super.init()
        ref = Firebase(url:"https://hi-there.firebaseio.com/")
    }

    // Login a user with the given Data
    func loginUserWithData(authData: FAuthData) {
        var profileImageUrl = authData.providerData["cachedUserProfile"]?["profile_image_url_https"] as? String

        if profileImageUrl == nil {
            profileImageUrl = ""
        }

        let newUser = [
            "provider": authData.provider,
            "displayName": authData.providerData["displayName"] as? NSString as? String,
            "profileImage": profileImageUrl]

        currentUser = UserObject(name: authData.providerData["displayName"] as! String, profileImage: profileImageUrl, uniqueId: authData.uid)

        // uid is unique, so we use it as key!
        getUsersRef().childByAppendingPath(authData.uid).updateChildValues(newUser)

        // This reference gives information about the connection status
        let connectedRef = ref.childByAppendingPath(".info/connected")

        connectedRef.observeEventType(.Value, withBlock: { snapshot in
            let connected = snapshot.value as? Bool
            if connected != nil && connected! {
                // add this device to my user connection list
                let connectionRef = self.getConnectionsRef(self.currentUser.uniqueId).childByAutoId()
                connectionRef.setValue("YES")

                // when this device disconnects, remove it
                connectionRef.onDisconnectRemoveValue()

                // when user disconnects, update the last time he was seen online
                // sv means Server Value and computes the placeholder value!
                self.getLastOnlineRef(self.currentUser.uniqueId).onDisconnectSetValue([".sv": "timestamp"])
            }
        })
    }

    // Delete a conversation with a user
    func deleteConversation(withUser user: UserObject) {
        // Get the conversation ID
        let conversationRef = pathToUserConversation(currentUser.uniqueId, otherUserId: user.uniqueId)
        conversationRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            if let key = snapshot.value["chatId"] as? String {
                // Remove the conversation and all the messages
                self.pathToConversation(key).removeValue()

                // Remove the stored references
                self.pathToUserConversation(self.currentUser.uniqueId, otherUserId: user.uniqueId).removeValue()
                self.pathToUserConversation(user.uniqueId, otherUserId: self.currentUser.uniqueId).removeValue()
            }
        })
    }

    // Send a message to a conversation
    func sendMessage(msg: JSQMessage, toChat: String) {
        let messagesRef = ref.childByAppendingPath("conversations/\(toChat)")

        messagesRef.childByAutoId().setValue([
            "text": msg.text,
            "sender": msg.senderId,
            "displayName": msg.senderDisplayName
            ])
    }

    // Get our user reference
    func getUsersRef() -> Firebase {
        return ref.childByAppendingPath("users")
    }

    // Get a conversation reference
    func pathToConversation(convId: String) -> Firebase {
        return ref.childByAppendingPath("conversations/\(convId)")
    }

    // Get a reference to a conversation with a user
    func pathToUserConversation(user: String, otherUserId: String) -> Firebase {
        return ref.childByAppendingPath("users/\(user)/conversations/\(otherUserId)")
    }

    // Get our conversation reference
    func getConversationsRef() -> Firebase {
        return ref.childByAppendingPath("conversations")
    }

    // Get presence reference
    func getLastOnlineRef(userId: String) -> Firebase {
        return ref.childByAppendingPath("users/\(userId)/lastTimeOnline")
    }

    // Get connections reference
    func getConnectionsRef(userId: String) -> Firebase {
        return ref.childByAppendingPath("users/\(userId)/connections")
    }
    
    // create a new user.
    func createNewAccount(uid: String, user: Dictionary<String, String>) {
        getUsersRef().childByAppendingPath(uid).setValue(user)
    }
}