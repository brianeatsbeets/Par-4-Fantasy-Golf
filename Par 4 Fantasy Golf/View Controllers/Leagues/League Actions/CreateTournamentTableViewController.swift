//
//  CreateTournamentTableViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 4/8/23.
//

// MARK: - Imported libraries

import UIKit

// MARK: - Main class

// This class/view controller allows the user to create a new tournament
class CreateTournamentTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    @IBOutlet var eventCell: UITableViewCell!
    @IBOutlet var eventNameLabel: UILabel!
    @IBOutlet var googleSheetIdCell: UITableViewCell!
    @IBOutlet var googleSheetIdLabel: UILabel!
    @IBOutlet var budgetTextField: UITextField!
    @IBOutlet var saveButton: UIBarButtonItem!
    
    var tournament: Tournament?
    var calendarEvents = [CalendarEvent]()
    var selectedEvent: CalendarEvent?
    var googleSheetId: String?
    
    // MARK: - View life cycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        eventCell.isUserInteractionEnabled = false
        saveButton.isEnabled = false
        
        Task {
            await fetchCalendarEvents()
            eventCell.isUserInteractionEnabled = true
            eventNameLabel.text = "Select event"
        }
    }
    
    // MARK: - Other functions
    
    // Fetch event calendar data
    func fetchCalendarEvents() async {
        
        // Construct URL
        // TODO: Provide today's date as the dates parameter
        let url = URL(string: "https://site.api.espn.com/apis/site/v2/sports/golf/pga/scoreboard")!
        
        do {
            // Request data from the URL
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Make sure we have a valid HTTP response
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let apiResponse = try? JSONDecoder().decode(CalendarApiResponse.self, from: data) {
                
                // Filter the calendar events to those whose end date is later than now
                calendarEvents = apiResponse.activeLeagues[0].calendar.filter({ event in
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withFullDate]
                    guard let eventEndDate = formatter.date(from: event.endDate) else { print("AAA"); return false }
                    
                    return eventEndDate > Date.now
                })
            } else {
                print("HTTP request error: \(response.description)")
            }
        } catch {
            print("Caught error from URLSession.shared.data function")
        }
    }
    
    // Toggle enabled state of save button
    func updateSaveButtonState() {
        let budgetText = budgetTextField.text ?? ""
        saveButton.isEnabled = !budgetText.isEmpty && selectedEvent != nil
    }
    
    // Detect when text field editing state has changed
    @IBAction func textEditingChanged(_ sender: UITextField) {
        updateSaveButtonState()
    }
    
    // MARK: - Navigation
    
    // Segue to SelectEventTableViewController, passing the list of upcoming events
    @IBSegueAction func segueToSelectEvent(_ coder: NSCoder) -> SelectEventTableViewController? {
        return SelectEventTableViewController(coder: coder, events: calendarEvents)
    }
    
    // Handle the incoming selected event
    @IBAction func unwindFromSelectEvent(segue: UIStoryboardSegue) {
        
        // Deselect cell
        eventCell.isSelected = false
        
        // Check that we have new league data to parse
        guard segue.identifier == "unwindSelectEvent",
              let sourceViewController = segue.source as? SelectEventTableViewController,
              let event = sourceViewController.selectedEvent
        else { return }
        
        print(event)
        
        // Update the selected event
        selectedEvent = event
        eventNameLabel.text = selectedEvent?.name
        print("Event ID: \(event.eventId)")
        
        // Update save button state
        updateSaveButtonState()
    }
    
    // Handle the incoming Google Sheet Id
    
    // TODO: Verify and fetch data upon saving in GoogleSheetsIDTableViewController
    @IBAction func unwindFromGoogleSheetId(segue: UIStoryboardSegue) {
        
        // Deselect cell
        googleSheetIdCell.isSelected = false
        
        // Check that we have new league data to parse
        guard segue.identifier == "unwindSaveSheetId",
              let sourceViewController = segue.source as? GoogleSheetsIDTableViewController else { return }
        
        // Update the selected event
        googleSheetId = sourceViewController.sheetId
        googleSheetIdLabel.text = googleSheetId
    }
    
    // Compile the league data for sending back to the league detail table view controller
    @IBAction func saveButtonPressed(_ sender: Any) {
        saveButton.isEnabled = false
        
        guard let selectedEvent = selectedEvent,
              let startDate = selectedEvent.startDate.espnDateStringToDouble(),
              let endDate = selectedEvent.endDate.espnDateStringToDouble() else { return }
        
        let budget = Int(budgetTextField.text ?? "") ?? 0
        let eventId = selectedEvent.eventId
        
        Task {
            
            //await fetchGoogleSheetData()
            
            // Fetch tournament athletes
            let athletes = await Tournament.fetchEventAthletes(eventId: eventId)
            
            // Create new tournament object
            tournament = Tournament(name: selectedEvent.name, startDate: startDate, endDate: endDate, budget: budget, athletes: athletes, espnId: eventId)
            
            // Segue back to LeagueDetailTableViewController
            performSegue(withIdentifier: "unwindCreateTournament", sender: nil)
        }
    }
    
    func fetchGoogleSheetData() async -> [AthleteBetData]? {
        
        // Construct URL
        let url = URL(string: "https://docs.google.com/spreadsheets/d/\(googleSheetId!)/export?format=tsv")!
        var athleteBetData: [AthleteBetData]?
        
        Task {
            do {
                // Request data from the URL
                let (data, response) = try await URLSession.shared.data(from: url)
                
                // Make sure we have a valid HTTP response and that the data can be decoded into a string
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200,
                   let tsvResponse = String(data: data, encoding: .utf8) {
                    
                    athleteBetData = parseAthleteBetData(tsvString: tsvResponse)
                    
                    print(athleteBetData)
                    
                } else {
                    print("HTTP request error: \(response.description)")
                }
            } catch {
                print("Caught error from URLSession.shared.data function")
            }
        }
        
        return athleteBetData
    }
    
    // Parse the downloaded athlete bet data and return an array of usable objects
    func parseAthleteBetData(tsvString: String) -> [AthleteBetData] {
        var athleteBetData = [AthleteBetData]()
        
        // Remove instaces of carriage return
        let filteredCsvString = tsvString.replacingOccurrences(of: "\r", with: "")
        
        // Split the single string into an array of strings for each row
        var rows = filteredCsvString.components(separatedBy: "\n")
        
        // Remove the header row
        rows.removeFirst()
        
        // Parse each row and create a new AthleteBetData object from the contents
        for row in rows {
            let columns = row.components(separatedBy: "\t")
            
            let espnId = columns[0]
            let name = columns[1]
            let odds = columns[2]
            let value = columns[3]
            
            let singleAthleteBetData = AthleteBetData(espnId: espnId, name: name, odds: odds, value: value)
            athleteBetData.append(singleAthleteBetData)
        }
        
        return athleteBetData
    }
}
