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
    @IBOutlet var budgetTextField: UITextField!
    @IBOutlet var saveButton: UIBarButtonItem!
    
    var tournament: Tournament?
    var calendarEvents = [CalendarEvent]()
    var selectedEvent: CalendarEvent?
    
    // MARK: - View life cycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        eventCell.isUserInteractionEnabled = false
        eventNameLabel.text = "Loading events..."
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
    
    // Fetch event athletes
    func fetchEventAthletes(eventId: String) async -> [Athlete]? {
        
        var athletes = [Athlete]()
        
        // Construct URL
        let url = URL(string: "https://site.api.espn.com/apis/site/v2/sports/golf/leaderboard?event=\(eventId)")!
        
        do {
            // Request data from the URL
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Make sure we have a valid HTTP response
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let apiResponse = try? JSONDecoder().decode(EventApiResponse.self, from: data) {
                
                // Parse each competitor and create an Athlete from each one
                let competitors = apiResponse.events[0].competitions[0].competitors
                for competitor in competitors {
                    let name = competitor.athlete.displayName
                    let score = competitor.score.value
                    let id = competitor.id
                    athletes.append(Athlete(espnId: id, name: name, score: score))
                }
                
                // Sort the athletes
                athletes = athletes.sorted { $0.name < $1.name }
                
                return athletes
                
            } else {
                print("HTTP request error: \(response.description)")
                return nil
            }
        } catch {
            print("Caught error from URLSession.shared.data function")
            return nil
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
        
        // Deselect cell and update save button state
        eventCell.isSelected = false
        updateSaveButtonState()
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
            var athletes = [Athlete]()
            
            if let eventAthletes = await fetchEventAthletes(eventId: eventId) {
                athletes = eventAthletes
                print("Added athletes")
            } else {
                print("No athletes added to tournament")
            }
            
            // Create new tournament object
            tournament = Tournament(name: selectedEvent.name, startDate: startDate, endDate: endDate, budget: budget, athletes: athletes, espnId: eventId)
            
            // Segue back to LeagueDetailTableViewController
            performSegue(withIdentifier: "unwindCreateTournament", sender: nil)
        }
    }
}
