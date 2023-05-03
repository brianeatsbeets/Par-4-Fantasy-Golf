//
//  AccountViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 2/22/23.
//

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
        
        // Display a confirmation alert
        let confirmAlert = UIAlertController(title: "Are you sure?", message: "You won't be able to access any of your data until you sign in again.", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let signOutAction = UIAlertAction(title: "Sign Out", style: .destructive) { action in
            
            // Dismiss the current alert
            confirmAlert.dismiss(animated: true)
            
            // If there is an error, present it to the user; otherwise, transition to the sign in view controller
            do {
                try Auth.auth().signOut()
            } catch let error as NSError {
                
                guard let errorCode = AuthErrorCode.Code(rawValue: error.code) else {
                    self.displayAlert(title: "Sign Out Error", message: "Something went wrong, but we're not exactly sure why. If you continue to see this message, reach out to the developer for assistance.")
                    return
                }
                
                switch errorCode {
                case .networkError:
                    self.displayAlert(title: "Sign Out Error", message: "Looks like there was a network issue. Your connection could be slow, it may have been interrupted, or the server could be temporarily unreachable.")
                default:
                    self.displayAlert(title: "Sign Out Error", message: "Something went wrong, but we're not exactly sure why. If you continue to see this message, reach out to the developer for assistance.")
                }
                
                return
            }
            
            self.transitionToAuthenticationViewController()
        }
        
        confirmAlert.addAction(signOutAction)
        confirmAlert.addAction(cancelAction)
        
        present(confirmAlert, animated: true)
    }
    
    // MARK: - Navigation
    
    // Transition to the main tab bar controller
    // Is there a better way to do this? Seems a little wonky
    func transitionToAuthenticationViewController() {
        guard let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate else { return }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let authenticationRootViewController = storyboard.instantiateViewController(withIdentifier: "AuthenticationRoot")
        
        // Set a new root view controller
        sceneDelegate.setRootViewController(to: authenticationRootViewController)
    }
    

}
