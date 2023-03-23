//
//  MakePicksTableViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/23/23.
//

// MARK: - Imported libraries

import UIKit
import FirebaseAuth
import FirebaseDatabase

// MARK: - Main class

// This class/view controller allows the user to select their picks for a given league
class MakePicksTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    lazy var dataSource = createDataSource()
    var league: League
    var pickItems = [PickItem]()
    
    let leagueRef: DatabaseReference
    var refObservers: [DatabaseHandle] = []
    
    // MARK: - Initializers
    
    init?(coder: NSCoder, league: League) {
        self.league = league
        self.leagueRef = Database.database().reference(withPath: "leagues/" + league.id.uuidString)
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View life cycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pickItems = getPickItems()
        tableView.dataSource = dataSource
        title = league.name
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create league data observer
        createLeagueDataObserver()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Remove all observers
        refObservers.forEach(leagueRef.removeObserver(withHandle:))
        refObservers = []
    }
    
    // MARK: - Other functions
    
    // Create the reference observer for league data
    func createLeagueDataObserver() {
        
        // Observe league data
        let refHandle = leagueRef.observe(.value) { snapshot in
            
            // Fetch updated league
            guard let newLeague = League(snapshot: snapshot) else {
                print("Error fetching league detail data")
                return
            }
            
            self.league = newLeague
            self.title = newLeague.name
            self.pickItems = self.getPickItems()
            
            self.updateTableView()
        }
        
        refObservers.append(refHandle)
    }
    
    // Populate the list of PickItems to be used in the data source
    func getPickItems() -> [PickItem] {
        var pickItems = [PickItem]()
        
        // Check if we have existing picks
        if let userPicks = league.picks[Auth.auth().currentUser!.uid] {
            
            // If so, apply the existing user selections
            for athlete in league.athletes {
                pickItems.append(PickItem(athlete: athlete, isSelected: userPicks.contains([athlete])))
            }
        } else {
            
            // If not, mark all selections as false
            for athlete in league.athletes {
                pickItems.append(PickItem(athlete: athlete, isSelected: false))
            }
        }
        
        return pickItems
    }
}

// MARK: - Other models

// Helper struct to contain selection data
struct PickItem: Hashable {
    let athlete: String
    var isSelected: Bool
}

// MARK: - Extensions

// This extention houses table view management functions that utilize the diffable data source API
extension MakePicksTableViewController {
    
    // This enum declares table view sections
    enum Section: CaseIterable {
        case one
    }
    
    // Create the the data source and specify what to do with a provided cell
    func createDataSource() -> UITableViewDiffableDataSource<Section, PickItem> {
        
        return UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, selection in
            
            // Configure the cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "PickCell", for: indexPath) as! PickTableViewCell
            cell.configure(with: selection)

            return cell
        }
    }
    
    // Apply a snapshot with updated user pick data
    func updateTableView(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, PickItem>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(pickItems)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}

