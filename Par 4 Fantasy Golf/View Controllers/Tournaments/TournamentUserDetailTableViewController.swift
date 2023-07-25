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
    let selectedUserUsername: String
    var selectedUserPicks: [Athlete]
    
    // MARK: - Initializers
    
    init?(coder: NSCoder, selectedUserUsername: String, selectedUserPicks: [Athlete]) {
        self.selectedUserUsername = selectedUserUsername
        self.selectedUserPicks = selectedUserPicks
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View life cycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "\(selectedUserUsername)'s Picks"
        tableView.dataSource = dataSource
        updateTableView()
    }
}

// MARK: - Extensions

// This extention houses table view management functions that utilize the diffable data source API
extension TournamentUserDetailTableViewController {
    
    // UITableViewDiffableDataSource subclass with custom section headers
    class CustomHeaderDiffableDataSource: UITableViewDiffableDataSource<Section, Athlete> {
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            return snapshot().sectionIdentifiers[section].rawValue
        }
    }
    
    // MARK: - Section enum
    
    // This enum declares table view sections
    enum Section: String, CaseIterable, Hashable {
        case active = "Active"
        case cut = "Cut"
    }
    
    // MARK: - Other functions
    
    // Create the the data source and specify what to do with a provided cell
    func createDataSource() -> CustomHeaderDiffableDataSource {
        
        return CustomHeaderDiffableDataSource(tableView: tableView) { tableView, indexPath, athlete in
            
            // Configure the cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "PickedAthleteCell", for: indexPath)
            
            var config = cell.defaultContentConfiguration()
            config.text = athlete.name
            config.secondaryText = "Value: \(athlete.value) | Odds: \(athlete.odds) | Score: \(athlete.score.formattedScore())"
            cell.contentConfiguration = config

            return cell
        }
    }
    
    // Apply a snapshot with updated athlete data
    func updateTableView(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Athlete>()
        
        // Compile the athletes based on status
        let activeAthletes = selectedUserPicks.filter { !$0.isCut }.sorted(by: { $0.odds < $1.odds })
        let cutAthletes = selectedUserPicks.filter { $0.isCut }.sorted(by: { $0.odds < $1.odds })
        
        // Append the active section and active athletes, if any
        if !activeAthletes.isEmpty {
            snapshot.appendSections([.active])
            snapshot.appendItems(activeAthletes, toSection: .active)
        }
        
        // Append the cut section and cut athletes, if any
        if !cutAthletes.isEmpty {
            snapshot.appendSections([.cut])
            snapshot.appendItems(cutAthletes, toSection: .cut)
        }
        
        // Apply the snapshot
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}
