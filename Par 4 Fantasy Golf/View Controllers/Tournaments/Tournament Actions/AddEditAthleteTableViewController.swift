//
//  AddEditAthleteTableViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/23/23.
//

// MARK: - Imported libraries

import UIKit
import FirebaseDatabase

// MARK: - Main class

// This class/view controller allows the user to create or edit athletes for a given league
class AddEditAthleteTableViewController: UITableViewController {
    
    // MARK: - Properties

    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var espnIdTextField: UITextField!
    @IBOutlet var valueTextField: UITextField!
    @IBOutlet var oddsTextField: UITextField!
    @IBOutlet var scoreTextField: UITextField!
    @IBOutlet var saveButton: UIBarButtonItem!
    
    var athlete: Athlete?
    let athleteRef: DatabaseReference?
    
    // MARK: - Initializers
    
    init?(coder: NSCoder, athlete: Athlete?, athleteRefPath: String?) {
        self.athlete = athlete
        self.athleteRef = athleteRefPath != nil ? Database.database().reference(withPath: athleteRefPath!) : nil
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View life cycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Pre-populate data if we're editing an existing athlete
        if let athlete = athlete {
            nameTextField.text = athlete.name
            espnIdTextField.text = athlete.espnId
            valueTextField.text = athlete.value.description
            oddsTextField.text = athlete.odds.description
            scoreTextField.text = athlete.score.description
            title = athlete.name
        } else {
            title = "New Athlete"
            updateSaveButtonState()
        }
    }
    
    // MARK: - Other functions
    
    // Toggle enabled state of save button based on text field validation
    func updateSaveButtonState() {
        let nameText = nameTextField.text ?? ""
        let espnIdText = espnIdTextField.text ?? ""
        let valueText = valueTextField.text ?? ""
        let oddsText = oddsTextField.text ?? ""
        let scoreText = scoreTextField.text ?? ""
        saveButton.isEnabled = !nameText.isEmpty && !espnIdText.isEmpty && !valueText.isEmpty && !oddsText.isEmpty && !scoreText.isEmpty && (Int(valueText) != nil) && (Int(oddsText) != nil) && (Int(scoreText) != nil)
    }
    
    // Detect when text field editing state has changed
    @IBAction func textEditingChanged(_ sender: UITextField) {
        updateSaveButtonState()
    }

    // MARK: - Navigation

    // Prep athlete property before returning to LeagueDetailsTableViewController
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "unwindSaveAthlete" else { return }
        
        let name = nameTextField.text ?? ""
        let espnId = espnIdTextField.text ?? ""
        let odds = Int(oddsTextField.text ?? "") ?? 0
        let value = Int(valueTextField.text ?? "") ?? 0
        let score = Int(scoreTextField.text ?? "") ?? 0
        
        // Create new athlete object or update values to existing athlete
        if athlete != nil {
            athlete!.name = name
            athlete!.espnId = espnId
            athlete!.odds = odds
            athlete!.value = value
            athlete!.score = score
        } else {
            athlete = Athlete(espnId: "nil", name: name, odds: odds, value: value, score: score)
        }
    }
}
