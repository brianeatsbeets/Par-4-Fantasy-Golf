//
//  LeagueUserDetailTableViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/29/23.
//

// MARK: - Imported libraries

import UIKit
import FirebaseAuth
import FirebaseDatabase

// MARK: - Main class

// This class/view controller allows the user to manage athletes for a given league
class LeagueUserDetailTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    lazy var dataSource = createDataSource()
    var league: League
    var userId: String
    
    // MARK: - Initializers
    
    init?(coder: NSCoder, userId: String, league: League) {
        self.league = league
        self.userId = userId
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
}

// MARK: - Extensions

// This extention houses table view management functions that utilize the diffable data source API
extension LeagueUserDetailTableViewController {
    
    // MARK: - Section enum
    
    // This enum declares table view sections
    enum Section: CaseIterable {
        case one
    }
    
    // MARK: - Other functions
    
    // Create the the data source and specify what to do with a provided cell
    func createDataSource() -> UITableViewDiffableDataSource<Section, LeagueUserDetail> {
        
        return UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, athlete in
            
            // Configure the cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "LeagueUserCell", for: indexPath)
            
            var config = cell.defaultContentConfiguration()
            config.text = athlete.name
            config.secondaryText = "Value: \(athlete.value) | Odds: \(athlete.odds) | Score: \(athlete.score)"
            cell.contentConfiguration = config

            return cell
        }
        
        return dataSource
    }
    
    // Apply a snapshot with updated athlete data
    func updateTableView(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, LeagueUserDetail>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(league.athletes)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}
