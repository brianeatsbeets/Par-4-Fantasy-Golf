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
    
    // MARK: - Initializers
    
    init?(coder: NSCoder, league: League) {
        self.league = league
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
        title = "Picks for \(league.name)"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateTableView(animated: false)
    }
    
    // MARK: - Other functions
    
    // Populate the list of PickItems to be used in the data source
    func getPickItems() -> [PickItem] {
        var pickItems = [PickItem]()
        
        // Check if we have existing picks
        if let userPicks = league.picks[Auth.auth().currentUser!.uid] {
            
            // If so, apply the existing user selections
            for athlete in league.athletes {
                pickItems.append(PickItem(athlete: athlete, isSelected: userPicks.contains([athlete.id])))
            }
        } else {
            
            // If not, mark all selections as false
            for athlete in league.athletes {
                pickItems.append(PickItem(athlete: athlete, isSelected: false))
            }
        }
        
        return pickItems
    }
    
    // Update the data source when a cell is tapped
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let dataSourcePick = dataSource.itemIdentifier(for: indexPath),
              let index = pickItems.firstIndex(of: dataSourcePick) else { return }
        
        tableView.deselectRow(at: indexPath, animated: false)
        pickItems[index].isSelected.toggle()
        updateTableView(animated: false)
    }
}

// MARK: - Other models

// Helper struct to contain selection data
struct PickItem: Hashable {
    let athlete: Athlete
    var isSelected: Bool
}

// MARK: - Extensions

// This extention houses table view management functions that utilize the diffable data source API
extension MakePicksTableViewController {
    
    // MARK: - Section enum
    
    // This enum declares table view sections
    enum Section: CaseIterable {
        case one
    }
    
    // MARK: - Other functions
    
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

