//
//  CreateLeagueTableViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 2/28/23.
//

// TODO: Validate input fields

// MARK: - Imported libraries

import UIKit

// MARK: - Main class

// This class/view controller allows the user to create a new league
class CreateLeagueTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    var league: League?
    
    // IBOutlets
    
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var startDatePicker: UIDatePicker!
    
    // MARK: - View life cycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Other functions
    
    // MARK: - Navigation
    
    // Compile the league data for sending back to the leagues table view controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "createLeagueUnwind" {
            league = League(name: nameTextField.text ?? "", startDate: startDatePicker.date.timeIntervalSince1970)
        }
    }
}
