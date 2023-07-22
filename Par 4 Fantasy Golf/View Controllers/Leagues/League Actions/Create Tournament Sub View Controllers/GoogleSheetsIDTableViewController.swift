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
    
    // This enum provides error cases for fetching Google sheet data
    enum GoogleSheetError: Error {
        case dataTaskError
        case invalidHttpResponse
        case decodingError
    }
    
    // Fetch the athlete bet data from the Google sheet
    func fetchGoogleSheetData(url: URL) async -> String? {
        
        let downloadTask = Task { () -> String in
            let data: Data
            let response: URLResponse
            
            do {
                // Request data from the URL
                (data, response) = try await URLSession.shared.data(from: url)
            } catch {
                print("Caught error from URLSession.shared.data function")
                throw GoogleSheetError.dataTaskError
            }
            
            // Make sure we have a valid HTTP response
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { throw GoogleSheetError.invalidHttpResponse }
            
            // Make sure that the data can be decoded into a string
            if let tsvResponse = String(data: data, encoding: .utf8) {
                // Return the response
                return tsvResponse
            } else {
                throw GoogleSheetError.decodingError
            }
        }
        
        let result = await downloadTask.result
        var athleteBetData: String? = nil
        
        do {
            // Attempt to return the resulting string
            athleteBetData = try result.get()
        } catch GoogleSheetError.dataTaskError {
            self.displayAlert(title: "Google Sheets Error", message: "Looks like there was a network issue when fetching the Google Sheet data. Your connection could be slow, or it may have been interrupted.")
        } catch GoogleSheetError.invalidHttpResponse {
            self.displayAlert(title: "Google Sheets Error", message: "Looks like there was an issue when fetching the Google Sheet data. The server might be temporarily unreachable.")
        } catch GoogleSheetError.decodingError {
            self.displayAlert(title: "Google Sheets Error", message: "Looks like there was an issue when decoding the Google Sheet data. If you see this message, please reach out to the developer.")
        } catch {
            self.displayAlert(title: "Google Sheets Error", message: "Something went wrong, but we're not exactly sure why. If you continue to see this message, reach out to the developer for assistance.")
        }
        
        return athleteBetData
    }
    
    // MARK: - Navigation
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        
        // Create alert in case we have an invalid URL or Google Sheet ID
        let invalidSheetIdAlert = UIAlertController(title: "Invalid Google Sheet ID", message: "The ID you provided did not return a valid Google Sheet. Please double-check your input and try again.", preferredStyle: .alert)
        invalidSheetIdAlert.addAction(UIAlertAction(title: "OK", style: .default))
        
        // Construct URL using the provided Google sheet id
        guard let url = URL(string: "https://docs.google.com/spreadsheets/d/\(googleSheetIdTextField.text!)/export?format=tsv") else {
            present(invalidSheetIdAlert, animated: true)
            return
        }
        
        displayLoadingIndicator(animated: true)
        
        Task {
            
            // Check if we received valid data from the Google sheet id
            if let athleteBetData = await fetchGoogleSheetData(url: url) {
                self.athleteBetData = athleteBetData
                self.sheetId = googleSheetIdTextField.text!
                
                dismissLoadingIndicator(animated: false)
                performSegue(withIdentifier: "unwindSaveSheetId", sender: nil)
            } else {
                dismissLoadingIndicator(animated: true)
                self.present(invalidSheetIdAlert, animated: true)
            }
        }
    }
}
