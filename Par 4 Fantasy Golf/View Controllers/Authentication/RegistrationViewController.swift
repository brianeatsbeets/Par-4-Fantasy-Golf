//
//  RegistrationViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/1/23.
//

// MARK: - Imported libraries

import UIKit
import FirebaseAuth
import FirebaseDatabase

// MARK: - Main class

// This class/view controller allows the user to register for an account
class RegistrationViewController: UIViewController {
    
    // MARK: - Properties
    
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var registerButton: UIButton!
    
    let ref = Database.database().reference(withPath: "users")
    
    // MARK: - View life cycle functions

    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerButton.isEnabled = false
    }
    
    // MARK: - Other functions
    
    // Attempt to create a new account
    @IBAction func registerButtonPressed() {
        displayLoadingIndicator(animated: true)
        
        Auth.auth().createUser(withEmail: emailTextField.text!, password: passwordTextField.text!) { authResult, error in
            
            // If there was an error, present it to the user. Otherwise, transition to the Leagues view
            if let error = error as NSError? {
                
                self.dismissLoadingIndicator(animated: true)
                
                guard let errorCode = AuthErrorCode.Code(rawValue: error.code) else {
                    self.displayAlert(title: "Registration Error", message: "Something went wrong, but we're not exactly sure why. If you continue to see this message, reach out to the developer for assistance.")
                    return
                }
                
                switch errorCode {
                case .invalidEmail:
                    self.displayAlert(title: "Registration Error", message: "That email address isn't valid. Double-check it and try registering again.")
                case .emailAlreadyInUse:
                    self.displayAlert(title: "Registration Error", message: "Looks like there's already an account with that email address.")
                case .networkError:
                    self.displayAlert(title: "Registration Error", message: "Looks like there was a network issue. Your connection could be slow, it may have been interrupted, or the server could be temporarily unreachable.")
                case .weakPassword:
                    self.displayAlert(title: "Registration Error", message: "Your password must have at least six characters.")
                default:
                    self.displayAlert(title: "Registration Error", message: "Something went wrong, but we're not exactly sure why. If you continue to see this message, reach out to the developer for assistance.")
                }
            } else {
                
                // Get user data
                let userId = authResult!.user.uid
                let user = User(id: userId, email: self.emailTextField.text!)
                
                // Save the user to Firebase
                user.databaseReference.setValue(user.toAnyObject())
                
                self.transitionToTabBarController()
            }
        }
    }
    
    // Toggle enabled state of sign in button
    @IBAction func textEditingChanged() {
        let emailText = emailTextField.text ?? ""
        let passwordText = passwordTextField.text ?? ""
        registerButton.isEnabled = !emailText.isEmpty && !passwordText.isEmpty
    }
    
    // MARK: - Navigation

     // Transition to the main tab bar controller
     // Is there a better way to do this? Seems a little wonky
    func transitionToTabBarController() {
        guard let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate else { return }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mainTabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarRoot")
        
        dismissLoadingIndicator(animated: false)
        
        // Set a new root view controller
        sceneDelegate.setRootViewController(to: mainTabBarController)
    }

}
