//
//  TournamentUserDetailTableViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/29/23.
//

// MARK: - Imported libraries

import UIKit
import FirebaseDatabase

// MARK: - Main class

// This class/view controller allows the user to view other users' picks for a given tournament
class TournamentUserDetailTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    lazy var dataSource = createDataSource()
    let selectedUserEmail: String
    var selectedUserPicks: [Athlete]
    
    // MARK: - Initializers
    
    init?(coder: NSCoder, selectedUserEmail: String, selectedUserPicks: [Athlete]) {
        self.selectedUserEmail = selectedUserEmail
        self.selectedUserPicks = selectedUserPicks
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View life cycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Picks for \(selectedUserEmail)"
        tableView.dataSource = dataSource
        updateTableView()
    }
}

// MARK: - Extensions

// This extention houses table view management functions that utilize the diffable data source API
extension TournamentUserDetailTableViewController {
    
    // MARK: - Section enum
    
    // This enum declares table view sections
    enum Section: CaseIterable {
        case one
    }
    
    // MARK: - Other functions
    
    // Create the the data source and specify what to do with a provided cell
    func createDataSource() -> UITableViewDiffableDataSource<Section, Athlete> {
        
        return UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, athlete in
            
            // Configure the cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "PickedAthleteCell", for: indexPath)
            
            var config = cell.defaultContentConfiguration()
            config.text = athlete.isCut ? athlete.name + " (CUT)" : athlete.name
            config.secondaryText = "Value: \(athlete.value) | Odds: \(athlete.odds) | Score: \(athlete.score)"
            cell.contentConfiguration = config

            return cell
        }
    }
    
    // Apply a snapshot with updated athlete data
    func updateTableView(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Athlete>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(selectedUserPicks)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}
