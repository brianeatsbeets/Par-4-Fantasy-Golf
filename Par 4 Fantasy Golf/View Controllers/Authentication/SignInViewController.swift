//
//  SignInViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 2/22/23.
//

// MARK: - Imported libraries

import UIKit
import FirebaseAuth

// MARK: - Main class

// This class/view controller allows the user to sign in
class SignInViewController: UIViewController {
    
    // MARK: - Properties
    
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var signInButton: UIButton!
    
    // MARK: - View life cycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        signInButton.isEnabled = false
    }
    
    // MARK: - Other functions
    
    // Attempt to sign the user in
    @IBAction func signInTapped() {
        displayLoadingIndicator(animated: true)
        
        Auth.auth().signIn(withEmail: emailTextField.text!, password: passwordTextField.text!) { authResult, error in
            
            // If there was an error, present it to the user. Otherwise, transition to the Leagues view
            if let error = error as NSError? {
                
                self.dismissLoadingIndicator(animated: true)
                
                guard let errorCode = AuthErrorCode.Code(rawValue: error.code) else {
                    self.displayAlert(title: "Sign In Error", message: "Something went wrong, but we're not exactly sure why. If you continue to see this message, reach out to the developer for assistance.")
                    return
                }
                
                switch errorCode {
                case .invalidEmail, .userNotFound, .wrongPassword:
                    self.displayAlert(title: "Sign In Error", message: "We can't find an account with the credentials you provided.")
                case .networkError:
                    self.displayAlert(title: "Sign In Error", message: "Looks like there was a network issue. Your connection could be slow, it may have been interrupted, or the server could be temporarily unreachable.")
                default:
                    self.displayAlert(title: "Sign In Error", message: "Something went wrong, but we're not exactly sure why. If you continue to see this message, reach out to the developer for assistance.")
                }
            } else {
                self.transitionToTabBarController()
            }
        }
    }
    
    // Toggle enabled state of sign in button
    @IBAction func textEditingChanged() {
        let emailText = emailTextField.text ?? ""
        let passwordText = passwordTextField.text ?? ""
        signInButton.isEnabled = !emailText.isEmpty && !passwordText.isEmpty
    }
    
    @IBAction func forgotPasswordPressed(_ sender: Any) {
        
        // Create initial alert
        let resetPasswordAlert = UIAlertController(title: "Forgot Password?", message: "Enter your email address and tap OK. If the email address is valid, you will recieve instructions on how to reset your password.", preferredStyle: .alert)
        resetPasswordAlert.addTextField()
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        let search = UIAlertAction(title: "OK", style: .default) { _ in
            
            // Grab the user-entered email
            let email = resetPasswordAlert.textFields![0].text ?? ""
            
            Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
                
                // Make sure self is still allocated; otherwise, cancel the operation
                guard let self else { return }
                
                // If there was an error, present it to the user. Otherwise, transition to the Leagues view
                if let error = error as NSError? {
                    
                    guard let errorCode = AuthErrorCode.Code(rawValue: error.code) else {
                        self.displayAlert(title: "Password Reset Error", message: "Something went wrong, but we're not exactly sure why. If you continue to see this message, reach out to the developer for assistance.")
                        return
                    }
                    
                    switch errorCode {
                    case .invalidEmail:
                        self.displayAlert(title: "Password Reset Error", message: "It doesn't look like what you entered was an email address. Make sure to follow the format of email@example.com.")
                    case .userNotFound:
                        break
                    case .networkError:
                        self.displayAlert(title: "Password Reset Error", message: "Looks like there was a network issue. Your connection could be slow, it may have been interrupted, or the server could be temporarily unreachable.")
                    default:
                        self.displayAlert(title: "Password Reset Error", message: "Something went wrong, but we're not exactly sure why. If you continue to see this message, reach out to the developer for assistance.")
                    }
                }
            }
        }
        
        // Add the alert actions
        resetPasswordAlert.addAction(cancel)
        resetPasswordAlert.addAction(search)
        
        // Present the alert
        present(resetPasswordAlert, animated: true)
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
