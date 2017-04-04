//
//  CreateAccountViewController.swift
//  hiThereMessaging
//
//  Created by Project on 5/3/16.
//  Copyright © 2016 iOSFinalProject. All rights reserved.
//

import UIKit
import Firebase

class CreateAccountViewController: UIViewController {

    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBAction func createAccount(sender: AnyObject) {
        
        let username = usernameTextField.text
        let email = emailTextField.text
        let password = passwordTextField.text
        
        if username != "" && email != "" && password != "" {
            
            // Set Email and Password for the New User.
            FirebaseConnector.sharedInstance.ref.createUser(email, password: password, withValueCompletionBlock: { error, result in
                if error != nil {
                    
                    // There was a problem.
                    self.signupErrorAlert("Oops!", message: "Having some trouble creating your account. Try again.")
                } else {
                    
                    // Create and Login the New User with authUser
                    FirebaseConnector.sharedInstance.ref.authUser(email, password: password, withCompletionBlock: {
                        err, authData in
                        let user = ["provider": authData.provider!, "email": email!, "username": username!]
                        
                        // Seal the deal in FirebaseConnector.swift.
                        FirebaseConnector.sharedInstance.createNewAccount(authData.uid, user: user)
                    })
                    
                    // Store the uid for future access - handy!
                    NSUserDefaults.standardUserDefaults().setValue(result ["uid"], forKey: "uid")
                    
                    // Enter the app.
                    self.performSegueWithIdentifier("NewUserLoggedIn", sender: nil)
                }
            })
        } else {
            signupErrorAlert("Thamba !", message: "Please enter your email, password, and a username.")
        }
    }
    
    
    @IBAction func cancelCreateAccount(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: {})
    }

    func signupErrorAlert(title: String, message: String) {
        
        // Called upon signup error to let the user know signup didn't work.
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let action = UIAlertAction(title: "Ok", style: .Default, handler: nil)
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
