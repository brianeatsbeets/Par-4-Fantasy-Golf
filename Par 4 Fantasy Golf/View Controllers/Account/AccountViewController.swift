//
//  AccountViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 2/22/23.
//

// TODO: Have the user confirm before signing out

// MARK: - Imported libraries

import UIKit
import FirebaseAuth

// MARK: - Main class

// This class/view controller allows the user to manage their account
class AccountViewController: UIViewController {

    // MARK: - Properties
    
    @IBOutlet var emailLabel: UILabel!
    
    // MARK: - View life cycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateUI()
    }
    
    // MARK: - Other functions
    
    func updateUI() {
        if let user = Auth.auth().currentUser {
            emailLabel.text = "Email: " + user.email!
        } else {
            emailLabel.text = "No email found"
        }
    }
    
    // Attempt to sign the user out
    @IBAction func signOutPressed() {
        
        // If there is an error, present it to the user; otherwise, transition to the sign in view controller
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
            return
        }
        
        print("Sign out successful!")
        transitionToAuthenticationViewController()
    }
    
    // MARK: - Navigation
    
    // Transition to the main tab bar controller
    // Is there a better way to do this? Seems a little wonky
    func transitionToAuthenticationViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let authenticationRootViewController = storyboard.instantiateViewController(withIdentifier: "AuthenticationRoot")
        
        // Set a new root view controller
        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.setRootViewController(to: authenticationRootViewController)
    }
    

}
