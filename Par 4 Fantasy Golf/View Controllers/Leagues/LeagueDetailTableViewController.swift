//
//  LeagueDetailTableViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/3/23.
//

// MARK: - Imported libraries

import UIKit
import FirebaseDatabase

// MARK: - Main class

// This class/view controller displays details for the selected league
class LeagueDetailTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    lazy var dataSource = createDataSource()
    var league: League
    
    let ref: DatabaseReference
    var refObservers: [DatabaseHandle] = []
    
    // MARK: - Initializers
    
    init?(coder: NSCoder, league: League) {
        self.league = league
        self.ref = Database.database().reference(withPath: "leagues/" + league.id.uuidString)
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View life cycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = dataSource
        
        title = league.name
        
        updateTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        createLeagueDataObserver()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Remove all observers
        refObservers.forEach(ref.removeObserver(withHandle:))
        refObservers = []
    }
    
    // MARK: - Other functions
    
    // Create the reference observer for league data
    func createLeagueDataObserver() {
        
        // Observe league data
        let refHandle = ref.observe(.value) { snapshot in
            
            // Fetch updated league
            guard let newLeague = League(snapshot: snapshot) else {
                print("Error fetching league detail data")
                return
            }
            
            // Update local datasource and table view
            self.league = newLeague
            self.title = newLeague.name
            self.updateTableView()
        }
        
        refObservers.append(refHandle)
    }
}

// MARK: - Extensions

// This extention houses table view management functions that utilize the diffable data source API
extension LeagueDetailTableViewController {
    
    // This enum declares table view sections
    enum Section: CaseIterable {
        case one
    }
    
    // Create the the data source and specify what to do with a provided cell
    func createDataSource() -> UITableViewDiffableDataSource<Section, League> {
        
        return UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, league in
            
            // Configure the cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "LeagueDetailCell", for: indexPath) as! LeagueStandingTableViewCell
            cell.configure(with: league)

            return cell
        }
    }
    
    // Apply a snapshot with updated league data
    func updateTableView(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, League>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems([league])
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}


