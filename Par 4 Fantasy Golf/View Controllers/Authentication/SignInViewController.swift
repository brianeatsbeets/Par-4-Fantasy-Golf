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
    
    // MARK: - View life cycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Other functions
    
    // Attempt to sign the user in
    @IBAction func signInTapped() {
        
        displayLoadingIndicator(animated: true)
        
        Auth.auth().signIn(withEmail: emailTextField.text!, password: passwordTextField.text!) { [weak self] authResult, error in
            guard let strongSelf = self else { return }
            
            // If there was an error, present it to the user. Otherwise, transition to the Leagues view
            if let error = error as NSError? {
                
                strongSelf.dismissLoadingIndicator(animated: true)
                
                guard let errorCode = AuthErrorCode.Code(rawValue: error.code) else {
                    strongSelf.displayAlert(title: "Sign In Error", message: "Something went wrong, but we're not exactly sure why. If you continue to see this message, reach out to the developer for assistance.", alertType: .ok)
                    return
                }
                
                switch errorCode {
                case .invalidEmail, .userNotFound, .wrongPassword:
                    strongSelf.displayAlert(title: "Sign In Error", message: "We can't find an account with the credentials you provided.", alertType: .ok)
                case .networkError:
                    strongSelf.displayAlert(title: "Sign In Error", message: "Looks like there was a network issue. Your connection could be slow, it may have been interrupted, or the server could be temporarily unreachable.", alertType: .ok)
                default:
                    strongSelf.displayAlert(title: "Sign In Error", message: "Something went wrong, but we're not exactly sure why. If you continue to see this message, reach out to the developer for assistance.", alertType: .ok)
                }
            } else {
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
