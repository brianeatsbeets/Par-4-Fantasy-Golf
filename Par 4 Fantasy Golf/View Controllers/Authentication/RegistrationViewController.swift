//
//  RegistrationViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/1/23.
//

// TODO: Validate text fields
// TODO: Add password confirmation text field
// TODO: Provide error feedback via alert
// TODO: Transition to tab bar controller with animation

// MARK: - Imported libraries

import UIKit
import FirebaseAuth
import FirebaseDatabase

// MARK: - Main class

// This class/view controller allows the user to register for an account
class RegistrationViewController: UIViewController {
    
    // MARK: - Properties
    
    let ref = Database.database().reference(withPath: "users")
    
    // IBOutlets
    
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    
    // MARK: - View life cycle functions

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Other functions
    
    // Attempt to create a new account
    @IBAction func registerButtonPressed() {
        Auth.auth().createUser(withEmail: emailTextField.text!, password: passwordTextField.text!) { authResult, error in
            
            // If there was an error, present it to the user. Otherwise, transition to the Leagues view
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            } else if authResult == nil {
                print("Error: authResult is nil")
                return
            } else {
                print("Registration successful!")
                
                // Get user data
                let userId = authResult!.user.uid
                let user = User(id: userId, email: self.emailTextField.text ?? "")
                
                // Save the user to Firebase
                let usersRef = self.ref.child(userId)
                usersRef.setValue(user.toAnyObject())
                
                self.transitionToTabBarController()
            }
        }
    }
    
    // MARK: - Navigation

     // Transition to the main tab bar controller
     // Is there a better way to do this? Seems a little wonky
     func transitionToTabBarController() {
         let storyboard = UIStoryboard(name: "Main", bundle: nil)
         let mainTabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarRoot")
         
         // Set a new root view controller
         (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.setRootViewController(to: mainTabBarController)
     }

}
