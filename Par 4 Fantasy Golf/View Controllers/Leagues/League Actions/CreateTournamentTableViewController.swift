//
//  CreateTournamentTableViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 4/6/23.
//

// TODO: Hide events that already have a tournament created
// TODO: Create an additional table view controller to allow the user to select a budget (have this one be the secondary view controller)

// MARK: - Imported libraries

import UIKit
import FirebaseAuth
import FirebaseDatabase

// MARK: - Main class

// This class/view controller allows the user to create a new tournament
class CreateTournamentTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    lazy var dataSource = createDataSource()
    var events: [CalendarEvent]
    var selectedEvent: CalendarEvent?
    weak var delegate: ManageAthletesDelegate?
    
    // MARK: - Initializers
    
    init?(coder: NSCoder, events: [CalendarEvent]) {
        self.events = events
        selectedEvent = nil
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View life cycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = dataSource
        updateTableView()
    }
    
    // MARK: - Other functions
    
    // Update the data source when a cell is tapped
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedEvent = dataSource.itemIdentifier(for: indexPath)
        performSegue(withIdentifier: "unwindCreateTournament", sender: nil)
    }
    
    // Dismiss the view controller when the cancel button is tapped
    @IBAction func cancelButtonPressed(_ sender: Any) {
        dismiss(animated: true)
    }
}

// MARK: - Extensions

// This extention houses table view management functions that utilize the diffable data source API
extension CreateTournamentTableViewController {
    
    // MARK: - Section enum
    
    // This enum declares table view sections
    enum Section: CaseIterable {
        case one
    }
    
    // MARK: - Other functions
    
    // Create the the data source and specify what to do with a provided cell
    func createDataSource() -> UITableViewDiffableDataSource<Section, CalendarEvent> {
        
        return UITableViewDiffableDataSource<Section, CalendarEvent>(tableView: tableView) { tableView, indexPath, event in
            
            // Configure the cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "CalendarEventCell", for: indexPath)
            
            var config = cell.defaultContentConfiguration()
            config.text = event.name
            config.secondaryText = "Start date: \(event.startDate.prettyDate()) | End date: \(event.endDate.prettyDate())"
            cell.contentConfiguration = config

            return cell
        }
    }
    
    // Apply a snapshot with updated athlete data
    func updateTableView(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, CalendarEvent>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(events)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}
