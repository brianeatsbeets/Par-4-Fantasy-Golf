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
    var athleteBetData: String?
    
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
    
    // Fetch the athlete bet data from the Google sheet
    // TODO: Build out errors a la https://www.hackingwithswift.com/quick-start/concurrency/how-to-get-a-result-from-a-task
    func fetchGoogleSheetData() async -> String? {
        
        // Construct URL using the provided Google sheet id
        let url = URL(string: "https://docs.google.com/spreadsheets/d/\(googleSheetIdTextField.text!)/export?format=tsv")!
        
        var athleteBetData: String?
        
        let downloadTask = Task { () -> String? in
            do {
                // Request data from the URL
                let (data, response) = try await URLSession.shared.data(from: url)
                
                // Make sure we have a valid HTTP response and that the data can be decoded into a string
                guard let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200,
                      let tsvResponse = String(data: data, encoding: .utf8) else { return nil }
                
                // Assign the response
                athleteBetData = tsvResponse
            } catch {
                print("Caught error from URLSession.shared.data function")
            }
            
            return athleteBetData
        }
        
        do {
            
            // Attempt to return the resulting string
            return try await downloadTask.result.get()
        }  catch {
            return nil
        }
    }
    
    // MARK: - Navigation
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        
        saveButton.isEnabled = false
        // TODO: Disable/enable cancel button as well (do this in other VCs)
        
        Task {
            
            // Check if we received valid data from the Google sheet id
            if let athleteBetData = await fetchGoogleSheetData() {
                self.athleteBetData = athleteBetData
                self.sheetId = googleSheetIdTextField.text!
                performSegue(withIdentifier: "unwindSaveSheetId", sender: nil)
            } else {
                saveButton.isEnabled = true
                
                let alert = UIAlertController(title: "Invalid Google Sheet ID", message: "The ID you provided did not return a valid Google Sheet. Please double-check your input and try again.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
        }
    }
}