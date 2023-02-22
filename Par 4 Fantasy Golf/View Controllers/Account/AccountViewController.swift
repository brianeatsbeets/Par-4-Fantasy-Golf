//
//  AccountViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 2/22/23.
//

import UIKit

class AccountViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    // MARK: - Navigation
    
    // Transition to the sign in view controller
    // Is there a better way to do this? Seems a little wonky
    @IBAction func signOutPressed() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let authenticationRootViewController = storyboard.instantiateViewController(withIdentifier: "AuthenticationRoot")
        
        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.setRootViewController(to: authenticationRootViewController)
    }
    

}
