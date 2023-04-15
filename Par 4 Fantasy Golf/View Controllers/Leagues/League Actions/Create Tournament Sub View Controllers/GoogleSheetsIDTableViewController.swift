//
//  GoogleSheetsIDTableViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 4/15/23.
//

// MARK: - Imported libraries

import UIKit

// MARK: - Main class

// This class/view controller allows the user to create a new tournament
class GoogleSheetsIDTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    @IBOutlet var googleSheetIdTextField: UITextField!
    @IBOutlet var saveButton: UIBarButtonItem!
    
    var sheetId = ""
    
    // MARK: - View life cycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        saveButton.isEnabled = false
    }
    
    // MARK: - Table view functions
    
    // Create a custom header view
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.font = label.font.withSize(12)
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.text = "If you would like to import player odds/value data from a Google Sheet, enter the Google Sheet ID in the field below. The ID can be found in the URL after the 'd' component, such as in the following example: https://docs.google.com/spreadsheets/d/GOOGLE_SHEET_ID/"
        return label
    }
    
    // MARK: - Other functions
    
    // Toggle enabled state of save button
    func updateSaveButtonState() {
        saveButton.isEnabled = googleSheetIdTextField.text != nil
    }
    
    // Detect when text field editing state has changed
    @IBAction func textEditingChanged(_ sender: UITextField) {
        updateSaveButtonState()
    }
    
    // MARK: - Navigation
    
    // Prep athlete property before returning to LeagueDetailsTableViewController
    // TODO: Verify that sheed id is valid before saving
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "unwindSaveSheetId" else { return }
        sheetId = googleSheetIdTextField.text!
    }
}
