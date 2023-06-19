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
    var athleteBetTsv: String?
    
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
                    formatter.timeZone = TimeZone.current
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
    @IBAction func unwindFromGoogleSheetId(segue: UIStoryboardSegue) {
        
        // Deselect cell
        googleSheetIdCell.isSelected = false
        
        // Check that we have new Google Sheets data to parse
        guard segue.identifier == "unwindSaveSheetId",
              let sourceViewController = segue.source as? GoogleSheetsIDTableViewController else { return }
        
        athleteBetTsv = sourceViewController.athleteBetData
        googleSheetId = sourceViewController.sheetId
        googleSheetIdLabel.text = googleSheetId
    }
    
    // Compile the league data for sending back to the league detail table view controller
    @IBAction func saveButtonPressed(_ sender: Any) {
        guard let selectedEvent = selectedEvent,
              let startDate = selectedEvent.startDate.espnDateStringToDouble(),
              let endDate = selectedEvent.endDate.espnDateStringToDouble() else { return }
        
        let budget = Int(budgetTextField.text ?? "") ?? 0
        let eventId = selectedEvent.eventId
        var athletes = [Athlete]()
        
        displayLoadingIndicator(animated: true)
        
        // Parse bet data if it was provided; otherwise, fetch athlete data from ESPN
        if athleteBetTsv != nil {
            athletes = parseAthleteBetData(athletes: athletes, tsvString: athleteBetTsv!)
            
            // Create new tournament object
            tournament = Tournament(name: selectedEvent.name, startDate: startDate, endDate: endDate, budget: budget, athletes: athletes, espnId: eventId)
            
            // Segue back to LeagueDetailTableViewController
            performSegue(withIdentifier: "unwindCreateTournament", sender: nil)
            
        } else {
            Task {
                
                // Fetch tournament athletes
                var athletes = [Athlete]()
                do {
                    athletes = try await Tournament.fetchEventAthleteData(eventId: eventId)
                } catch EventAthleteDataError.dataTaskError {
                    self.displayAlert(title: "Save Tournament Error", message: "Looks like there was a network issue when fetching tournament data. Your connection could be slow, or it may have been interrupted.")
                    dismissLoadingIndicator(animated: true)
                    return
                } catch EventAthleteDataError.invalidHttpResponse {
                    self.displayAlert(title: "Save Tournament Error", message: "Looks like there was an issue when fetching tournament data. The server might be temporarily unreachable.")
                    dismissLoadingIndicator(animated: true)
                    return
                } catch EventAthleteDataError.decodingError {
                    self.displayAlert(title: "Save Tournament Error", message: "Looks like there was an issue when decoding the tournament data. If you see this message, please reach out to the developer.")
                    dismissLoadingIndicator(animated: true)
                    return
                } catch EventAthleteDataError.noCompetitorData {
                    
                    // Create a custom alert with a completion handler in order to wait for user interaction before beginning segue
                    let noCompetitorDataAlert = UIAlertController(title: "No Player Data", message: "Just as a heads up, it doesn't look like there is any player data in ESPN for this tournament right now. You can enter your own player data by re-creating this tournament and providing a Google Sheet ID, or you can manually enter player information in the Manage Athletes page.", preferredStyle: .alert)
                    
                    let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                        noCompetitorDataAlert.dismiss(animated: true)
                        
                        // Create new tournament object
                        self.tournament = Tournament(name: selectedEvent.name, startDate: startDate, endDate: endDate, budget: budget, athletes: athletes, espnId: eventId)
                        
                        // Segue back to LeagueDetailTableViewController
                        self.performSegue(withIdentifier: "unwindCreateTournament", sender: nil)
                    }
                    
                    noCompetitorDataAlert.addAction(okAction)
                    present(noCompetitorDataAlert, animated: true)
                    return
                    
                } catch {
                    self.displayAlert(title: "Save Tournament Error", message: "Something went wrong, but we're not exactly sure why. If you continue to see this message, reach out to the developer for assistance.")
                    dismissLoadingIndicator(animated: true)
                    return
                }
                
                // Create new tournament object
                tournament = Tournament(name: selectedEvent.name, startDate: startDate, endDate: endDate, budget: budget, athletes: athletes, espnId: eventId)
                
                // Segue back to LeagueDetailTableViewController
                performSegue(withIdentifier: "unwindCreateTournament", sender: nil)
            }
        }
    }
    
    // Parse the downloaded athlete bet data and return updated athletes
    func parseAthleteBetData(athletes: [Athlete], tsvString: String) -> [Athlete] {
        var updatedAthletes = athletes
        
        // Remove instaces of carriage return
        let filteredCsvString = tsvString.replacingOccurrences(of: "\r", with: "")
        
        // Split the single string into an array of strings for each row
        var rows = filteredCsvString.components(separatedBy: "\n")
        
        // Remove the header row
        rows.removeFirst()
        
        // Check if athletes have been provided with the tournament data from ESPN
        if !updatedAthletes.isEmpty {
            
            // If so, parse each row and update the corresponding athlete
            for row in rows {
                
                // Separate the columns
                let columns = row.components(separatedBy: "\t")
                
                // Assign the fields and check for a matching athlete
                let espnId = columns[0]
                let filteredOdds = columns[2].filter("0123456789".contains)
                let filteredValue = columns[3].filter("0123456789".contains)
                
                guard let odds = Int(filteredOdds) else { print("Odds cast fail"); continue }
                guard let value = Int(filteredValue) else { print("Value cast fail"); continue }
                guard let index = athletes.firstIndex(where: { $0.espnId == espnId }) else {
                    print("Couldn't find matching athlete for \(columns[1])")
                    continue
                }
                
                updatedAthletes[index].odds = odds
                updatedAthletes[index].value = value
            }
        } else {
            
            // If not, parse each row and create a new athlete object
            for row in rows {
                
                // Separate the columns
                let columns = row.components(separatedBy: "\t")
                
                // Assign the fields and check for a matching athlete
                let espnId = columns[0]
                let name = columns[1]
                let filteredOdds = columns[2].filter("0123456789".contains)
                let filteredValue = columns[3].filter("0123456789".contains)
                
                guard let odds = Int(filteredOdds),
                      let value = Int(filteredValue) else {
                    print("Couldn't cast odds/value to Int")
                    continue
                }
                
                updatedAthletes.append(Athlete(espnId: espnId, name: name, odds: odds, value: value))
            }
        }
        
        return updatedAthletes
    }
}
