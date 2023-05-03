//
//  CreateLeagueTableViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 2/28/23.
//

// MARK: - Imported libraries

import UIKit
import FirebaseAuth

// MARK: - Main class

// This class/view controller allows the user to create a new league
class CreateLeagueTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    var league: League?
    let currentFirebaseUser = Auth.auth().currentUser!
    
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var saveButton: UIBarButtonItem!
    
    // MARK: - View life cycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        saveButton.isEnabled = false
    }
    
    // MARK: - Other functions
    
    // Toggle enabled state of save button
    @IBAction func textEditingChanged() {
        let nameText = nameTextField.text ?? ""
        saveButton.isEnabled = !nameText.isEmpty
    }
    
    // MARK: - Navigation
    
    // Compile the league data for sending back to the leagues table view controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "createLeagueUnwind" else { return }
        
        displayLoadingIndicator(animated: true)
        league = League(name: nameTextField.text!, creator: currentFirebaseUser.uid)
    }
}
