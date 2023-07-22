//
//  SelectEventTableViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 4/6/23.
//

// MARK: - Imported libraries

import UIKit
import FirebaseAuth
import FirebaseDatabase

// MARK: - Main class

// This class/view controller allows the user to create a new tournament
class SelectEventTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    lazy var dataSource = createDataSource()
    var events: [CalendarEvent]
    var selectedEvent: CalendarEvent?
    
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
        performSegue(withIdentifier: "unwindSelectEvent", sender: nil)
    }
}

// MARK: - Extensions

// This extention houses table view management functions that utilize the diffable data source API
extension SelectEventTableViewController {
    
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
            
            // Display tournament start and end date if they are convertible from the provided format
            if let startDate = event.startDate.espnDateStringToDouble(),
               let endDate = event.endDate.espnDateStringToDouble() {
                config.secondaryText = "Start date: \(startDate.formattedDate()) | End date: \(endDate.formattedDate())"
            }
            
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
