//
//  CreateLeagueTableViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 2/28/23.
//

// TODO: Validate input fields
// TODO: Aggregate fields/values before creating league in prepare(for segue:sender:)

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
    
    // MARK: - View life cycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Navigation
    
    // Compile the league data for sending back to the leagues table view controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "createLeagueUnwind" else { return }
        league = League(name: nameTextField.text ?? "")
    }
}
