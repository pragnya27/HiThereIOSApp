//
//  LoginViewController.swift
//  hiThereMessaging
//
//  Created by Project on 5/3/16.
//  Copyright © 2016 iOSFinalProject. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    var twitterAuth: TwitterAuthHelper!
    var accounts: [ACAccount]!


    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        twitterAuth = TwitterAuthHelper(firebaseRef: FirebaseConnector.sharedInstance.ref, apiKey: "9V5VRUAxye8tAFvriEtjWScXP")
        
        let loginBtn = UIButton(frame: CGRect(x: view.frame.width/2 - 130, y: view.frame.height/2 + 50, width: 260, height: 58))
        loginBtn.addTarget(self, action: "login", forControlEvents: UIControlEvents.TouchUpInside)
        loginBtn.setImage(UIImage(named: "twitter"), forState: UIControlState.Normal)
        view.addSubview(loginBtn)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // If we have the uid stored, the user is already logger in - no need to sign in again!
        if NSUserDefaults.standardUserDefaults().valueForKey("uid") != nil && FirebaseConnector.sharedInstance.currentUser_ref.authData != nil {
            self.performSegueWithIdentifier("CurrentlyLoggedIn", sender: nil)
        }
    }
    
    @IBAction func tryLogin(sender: AnyObject) {
        
        let email = emailTextField.text
        let password = passwordTextField.text
        
        if email != "" && password != "" {
            // Login with the Firebase's authUser method
            
            FirebaseConnector.sharedInstance.ref.authUser(email, password: password, withCompletionBlock: { error, authData in
                if error != nil {
                    print(error)
                    self.loginErrorAlert("Oops!", message: "Check your username and password.")
                } else {
                    
                    // Be sure the correct uid is stored.
                    NSUserDefaults.standardUserDefaults().setValue(authData.uid, forKey: "uid")
                    
                    // Enter the app!
                    self.performSegueWithIdentifier("CurrentlyLoggedIn", sender: nil)
                }
            })
            
        } else {
            
            // There was a problem
            loginErrorAlert("Oops!", message: "Don't forget to enter your email and password.")
        }
    }
    
    func loginErrorAlert(title: String, message: String) {
        
        // Called upon login error to let the user know login didn't work.
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let action = UIAlertAction(title: "Ok", style: .Default, handler: nil)
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    //login twitter
    func login() {
        twitterAuth.selectTwitterAccountWithCallback { (error, allAccounts) -> Void in
            if error != nil {
                self.accounts = [ACAccount]()
            } else {
                self.accounts = allAccounts as! [ACAccount]
            }
            self.handleTwitterAccounts(self.accounts)
        }
    }
    
    // Handle the amount of existing Twitter profiles
    func handleTwitterAccounts(accounts: [ACAccount]) {
        switch accounts.count {
        case 0: // No account detected on the device
            UIApplication.sharedApplication().openURL(NSURL(string: "https://twitter.com/signup")!)
        case 1: // Perfect, just 1 account
            self.authWith(accounts[0])
        default: // ok possible many accounts, need to select one
            self.selectTwitterAccount(accounts)
        }
    }
    
    // Authenticate with the selected account
    func authWith(account: ACAccount) {
        twitterAuth.authenticateAccount(account, withCallback: { (error, authData) -> Void in
            if error != nil {
                print(error)
            } else {
                FirebaseConnector.sharedInstance.loginUserWithData(authData)
                self.performSegueWithIdentifier("CurrentlyLoggedIn", sender: authData)
            }
        })
    }
    
    // Show the ActionSheet to select a user
    func selectTwitterAccount(accounts: [ACAccount]) {
        let alertCtrl = UIAlertController(title: "Choose Twitter Account", message: "for your Chat login", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        for account in accounts {
            alertCtrl.addAction(UIAlertAction(title: account.username, style: UIAlertActionStyle.Default, handler: { action in
                self.authWith(account)
            }))
        }
        self.presentViewController(alertCtrl, animated: true, completion: nil)
    }
}

    
    
           // MARK: - Navigation
/*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        super.prepareForSegue(segue, sender: sender)
        let navVc = segue.destinationViewController as! UINavigationController // 1
        let chatVc = navVc.viewControllers.first as! ChatViewController // 2
        chatVc.senderId = DataService.dataService.BASE_REF.authData.uid // 3
        //chatVc.senderDisplayName = DataService.dataService.BASE_REF.
        
    }
    */

