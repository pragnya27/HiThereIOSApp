//
//  MessagingTableViewController.swift
//  Messaging_HiThere
//
//  Created by Project on 5/8/16.
//  Copyright © 2016 iOSFinalProject. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class UsersTableViewController: UITableViewController {
    
    @IBOutlet weak var logoutButton: UIBarButtonItem!
    
    var users: [UserObject]!
    
    @IBAction func logout(sender: AnyObject) {
        
//        // unauth() is the logout method for the current user.
      //  FirebaseConnector.sharedInstance.currentUser_ref.unauth()
//          FirebaseConnector.sharedInstance.getConnectionsRef.(curre)
//        // Remove the user's uid from storage.
//        NSUserDefaults.standardUserDefaults().setValue(nil, forKey: "uid")
        
        // Head back to Login!
        let loginViewController = self.storyboard!.instantiateViewControllerWithIdentifier("Login")
        UIApplication.sharedApplication().keyWindow?.rootViewController = loginViewController
    }

    
    override func viewWillAppear(animated: Bool) {
        self.title = "Conversations"
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        //load users
        users = [UserObject]()
        FirebaseConnector.sharedInstance.getUsersRef().queryOrderedByKey().observeEventType(.ChildAdded, withBlock: { snapshot in
            if snapshot.key != FirebaseConnector.sharedInstance.currentUser?.uniqueId {
                // Filter out only other users
                if let username = snapshot.value["displayName"] as? String {
                    self.users.append(UserObject(name: username, profileImage: snapshot.value["profileImage"] as? String, uniqueId: snapshot.key))
                    self.tableView.reloadData()
                }
            }
        })
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    
    // MARK: TableView functions
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier("cell")! as UITableViewCell
        cell.textLabel?.text = self.users[indexPath.row].name        
        if let url = NSURL(string: self.users[indexPath.row].profileImageUrl!) {
            if let data = NSData(contentsOfURL: url) {
                cell.imageView?.image = UIImage(data: data)
            }
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("showChat", sender: users[indexPath.row])
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let user = users[indexPath.row]
            FirebaseConnector.sharedInstance.deleteConversation(withUser: user)
        }
    }
    
    // Set the other user id once we open a chat
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        let chatVC = segue.destinationViewController as! ChatDetailViewController
        if let data = sender as? UserObject {
            chatVC.otherUser = data
        }
    }
}
