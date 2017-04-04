//
//  ChatViewController.swift
//  Messaging_HiThere
//
//  Created by Project on 5/8/16.
//  Copyright © 2016 iOSFinalProject. All rights reserved.
//

import Foundation
import Firebase
import AVFoundation
import JSQMessagesViewController
import MobileCoreServices

class ChatDetailViewController: JSQMessagesViewController, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let imagePicker = UIImagePickerController()
    let synth = AVSpeechSynthesizer()
    var myUtterance = AVSpeechUtterance(string: "")
    var otherUser: UserObject!
    var messages = [JSQMessage]()
    var outgoingBubbleImageView = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleBlueColor())
    var incomingBubbleImageView = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleGreenColor())
    
    var conversationId: String!
    
    override func viewWillAppear(animated: Bool) {
        // Set parameters for JSQMessagesViewController
        self.senderId = FirebaseConnector.sharedInstance.currentUser.uniqueId
        self.senderDisplayName = FirebaseConnector.sharedInstance.currentUser.name
        // Set some parameters
        
//        automaticallyScrollsToMostRecentMessage = true
//        collectionView?.collectionViewLayout.springinessEnabled = true
        
        // Load the conversation
        checkForConversation(withUser: otherUser)
        
        // Update the online status
        setTitleForConversation()
        
        //Code commented below to enable image uploading as was causing hinderance
        
//        scrollToBottomAnimated(true)
//        showTypingIndicator = !showTypingIndicator
    }
    
    // Obeserve the online/offline state of the other user
    func setTitleForConversation() {
        FirebaseConnector.sharedInstance.getConnectionsRef(otherUser.uniqueId).observeEventType(.Value, withBlock: { snapshot in
            if snapshot.value is NSNull {
                // User has no connections, so he is offline
                self.title = "Offline"
                FirebaseConnector.sharedInstance.getLastOnlineRef(self.otherUser.uniqueId).observeSingleEventOfType(.Value, withBlock: { data in
                    if let time = data.value as? Double {
                        // Convert the timestamp to something useful
                        let dateFormatter = NSDateFormatter()
                        let date = NSDate(timeIntervalSince1970: time/1000)
                        dateFormatter.dateFormat = "MM/dd hh:mm a"
                        
                        self.title = "Last seen: \(dateFormatter.stringFromDate(date))"
                    }
                })
            } else {
                // User is online
                self.title = "Online"
            }
        })
    }
    
    // Check if we already have a unique conversation with this user
    func checkForConversation(withUser user: UserObject) {
        let conversationRef = FirebaseConnector.sharedInstance.pathToUserConversation(self.senderId, otherUserId: otherUser.uniqueId)
        conversationRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            if snapshot.value is NSNull {
                // We have to start a new conversation
                let newConversationRefKey = FirebaseConnector.sharedInstance.getConversationsRef().childByAutoId().key
                conversationRef.setValue(["chatId":newConversationRefKey])
                FirebaseConnector.sharedInstance.pathToUserConversation(self.otherUser.uniqueId, otherUserId: self.senderId).setValue(["chatId":newConversationRefKey])
                self.loadMessagesForConversation(newConversationRefKey)
            } else {
                // This conversation already exists
                self.loadMessagesForConversation(snapshot.value["chatId"] as! String)
            }
        })
    }
    
    
    // Load the stored messages for a given unique conversation id
    func loadMessagesForConversation(conversationId: String) {
        
        
        
        self.conversationId = conversationId
        let messagesRef = FirebaseConnector.sharedInstance.pathToConversation(conversationId)
        messagesRef.queryLimitedToFirst(25).observeEventType(FEventType.ChildAdded, withBlock: { (snapshot) in
            let text = snapshot.value["text"] as? String
            let sender = snapshot.value["sender"] as? String
            let displayName = snapshot.value["displayName"] as? String
            let message = JSQMessage(senderId: sender, displayName: displayName, text: text)
            self.messages.append(message)
            
            // Animates receiving
            self.finishReceivingMessage()
        })
    }
    
    // MARK: JSQMessagesViewController CollectionView functions
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        
        if message.senderId == self.senderId {
            return outgoingBubbleImageView
        }
        
        return incomingBubbleImageView
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        
        let message = messages[indexPath.item]
        var imageUrl: String?
        if otherUser.uniqueId == message.senderId {
            if let otherUserImage = otherUser.profileImageUrl {
                imageUrl = otherUserImage
            }
        } else {
            if let userImage = FirebaseConnector.sharedInstance.currentUser?.profileImageUrl {
                imageUrl = userImage
            }
        }
        if let stringUrl = imageUrl {
            if let url = NSURL(string: stringUrl) {
                if let data = NSData(contentsOfURL: url) {
                    let image = UIImage(data: data)
                    return JSQMessagesAvatarImage(placeholder: image)
                }
            }
        }
        let dummyColor = UIColor(red: 222/255, green: 223/255, blue: 224/255, alpha: 1)
        return JSQMessagesAvatarImage(placeholder: getImageWithColor(dummyColor, size: collectionView.collectionViewLayout.incomingAvatarViewSize))
    }
    
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        FirebaseConnector.sharedInstance.sendMessage(JSQMessage(senderId: senderId, senderDisplayName: senderDisplayName, date: date, text: text), toChat: self.conversationId)
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        // Animates sending
        self.finishSendingMessage()
        myUtterance = AVSpeechUtterance(string: text)
        myUtterance.rate = 0.5
        synth.speakUtterance(myUtterance)
        showTypingIndicator = !showTypingIndicator
//        scrollToBottomAnimated(true)
        
    }
    
    override func didPressAccessoryButton(sender: UIButton!) {
        // Create Action Sheet /AlertController with Send Photo Option
        
        let sheet = UIAlertController(title: "Media Messages", message: "Please select a media", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (alert: UIAlertAction!) -> Void in
            sheet.dismissViewControllerAnimated(true, completion: nil)
        }
        
        let sendPhoto = UIAlertAction(title: "Send Photo", style: UIAlertActionStyle.Default){ (alert: UIAlertAction!) -> Void in
            self.photoLibrary()
        }
        sheet.addAction(sendPhoto)
        sheet.addAction(cancel)
        presentViewController(sheet, animated: true, completion: nil)
        
//        imagePicker.allowsEditing = false
//        imagePicker.sourceType = .PhotoLibrary
//       imagePicker.showsCameraControls = true
//        presentViewController(imagePicker, animated: true, completion: nil)
//        imagePickerController(imagePicker,didFinishPickingMediaWithInfo info: [String : AnyObject]))
//        func imagePickerController(imagePicker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
//        {
//            let picture = info[UIImagePickerControllerEditedImage] as? UIImage
//            
//            if (info[UIImagePickerControllerEditedImage] as? UIImage) != nil
//            {
//                let mediaItem = JSQPhotoMediaItem(image: nil)
//                mediaItem.appliesMediaViewMaskAsOutgoing = true
//                mediaItem.image = UIImage(data: UIImageJPEGRepresentation(picture!, 0.5)!)
//                let sendMessage = JSQMessage(senderId: senderId, displayName: self.senderDisplayName, media: mediaItem)
//                
//                self.messages.append(sendMessage)
//                self.finishSendingMessage()
//            }
//            
//            imagePicker.dismissViewControllerAnimated(true, completion: nil)
//        }

    }

    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        
        let img = resizeImage(image)
        
        self.dismissViewControllerAnimated(true) { () -> Void in
            let imageData = UIImagePNGRepresentation(img)!
            let base64String = imageData.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
            
            let text = base64String
            let senderId = self.senderId
            let senderDisplayName = self.senderDisplayName
        
            let date = NSDate()
            
            FirebaseConnector.sharedInstance.sendMessage(JSQMessage(senderId: senderId, senderDisplayName: senderDisplayName, date: date, text: text), toChat: self.conversationId)
            
//            let messagesRef = FirebaseConnector.sharedInstance.pathToConversation(self.conversationId)
//            messagesRef.setValue(msgDict)            
            self.finishSendingMessage()
        }
        
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        
        let message = messages[indexPath.row]
        if !message.isMediaMessage{
            if message.senderId == self.senderId {
                cell.textView!.textColor = UIColor.blackColor()
            }else{
                cell.textView!.textColor = UIColor.whiteColor()
            }
        }        
        return cell
    }


    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    //Resize send image
    func resizeImage(img: UIImage) -> UIImage {
        
        let size = CGSizeApplyAffineTransform(img.size, CGAffineTransformMakeScale(0.5, 0.5))
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        img.drawInRect(CGRect(origin: CGPointZero, size: size))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
    
    //code referenced from: http://stackoverflow.com/questions/26542035/create-uiimage-with-solid-color-in-swift
    func getImageWithColor(color: UIColor, size: CGSize) -> UIImage {
        let rect = CGRectMake(0, 0, size.width, size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }    
    
    //Customiztion to Image Picker Functionality
    func photoLibrary(){
        self.imagePicker.allowsEditing = false
        self.imagePicker.delegate = self
        self.imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        self.imagePicker.mediaTypes = [kUTTypeImage as String]
        self.presentViewController(self.imagePicker, animated: true, completion: nil)
    }
}