//
//  SignInViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 2/22/23.
//

// TODO: Validate text fields
// TODO: Provide error feedback via alert
// TODO: Transition to tab bar controller with animation

// MARK: - Imported libraries

import UIKit
import FirebaseAuth

// MARK: - Main class

// This class/view controller allows the user to sign in
class SignInViewController: UIViewController {
    
    // MARK: - Properties
    
    // IBOutlets
    
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    
    // MARK: - View life cycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Other functions
    
    // Attempt to sign the user in
    @IBAction func signInTapped() {
        
        Auth.auth().signIn(withEmail: emailTextField.text!, password: passwordTextField.text!) { [weak self] authResult, error in
            guard let strongSelf = self else { return }
            
            // If there was an error, present it to the user. Otherwise, transition to the Leagues view
            if let error = error {
                print("Error: \(error.localizedDescription)")
            } else {
                print("Sign in successful!")
                strongSelf.transitionToTabBarController()
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
