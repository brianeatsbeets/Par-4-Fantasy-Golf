//
//  MakePicksTableViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/23/23.
//

// MARK: - Imported libraries

import UIKit
import FirebaseAuth

// MARK: - Main class

// This class/view controller allows the user to select their picks for a given tournament
class MakePicksTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    @IBOutlet var budgetLabel: UILabel!
    @IBOutlet var spentLabel: UILabel!
    @IBOutlet var saveButton: UIBarButtonItem!
    
    lazy var dataSource = createDataSource()
    var tournament: Tournament
    var pickItems = [PickItem]()
    var pickCount: Int {
        pickItems.filter { $0.isSelected }.count
    }
    var totalSpent = 0
    var sections = [Int]()
    var picksBySection = [Int: [PickItem]]()
    
    // MARK: - Initializers
    
    init?(coder: NSCoder, tournament: Tournament) {
        self.tournament = tournament
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View life cycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getPickItems()
        tableView.dataSource = dataSource
        updateUI()
        
        updateTableView(animated: false)
    }
    
    // MARK: - Other functions
    
    // Populate the list of PickItems to be used in the data source
    func getPickItems() {
        
        // Check if we have existing picks
        if let userPicks = tournament.pickIds[Auth.auth().currentUser!.uid] {
            
            // If so, apply the existing user selections
            for athlete in tournament.athletes {
                let pickItem = PickItem(athlete: athlete, isSelected: userPicks.contains([athlete.espnId]))
                if pickItem.isSelected {
                    totalSpent += pickItem.athlete.value
                }
                pickItems.append(pickItem)
            }
        } else {
            
            // If not, mark all selections as false
            for athlete in tournament.athletes {
                pickItems.append(PickItem(athlete: athlete, isSelected: false))
            }
        }
        
        // Sort picks by odds
        pickItems = pickItems.sorted(by: { $0.athlete.odds < $1.athlete.odds })
        
        updatePicksBySection()
    }
    
    // Update the section and item variables used by the data source
    func updatePicksBySection() {
        
        // Populate sections
        var sectionsSet = Set<Int>()
        for item in pickItems {
            sectionsSet.insert(item.athlete.value)
        }
        sections = sectionsSet.sorted(by: >)
        
        // Populate picksBySection
        for section in sections {
            picksBySection[section] = pickItems.filter { $0.athlete.value == section }
        }
    }
    
    // Update the UI elements
    func updateUI() {
        saveButton.isEnabled = pickCount >= 6
        title = "Picks for \(tournament.name)"
        budgetLabel.text = "Budget: $\(tournament.budget)"
        spentLabel.text = "Total Spent: $\(totalSpent)"
    }
    
    // Update the data source when a cell is selected
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let dataSourcePick = dataSource.itemIdentifier(for: indexPath),
              let index = pickItems.firstIndex(of: dataSourcePick) else { return }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let remainingBudget = tournament.budget - totalSpent
        
        // Helper function to reduce code duplication
        let updatePicksTable = { [self] in
            pickItems[index].isSelected.toggle()
            updatePicksBySection()
            spentLabel.text = "Total Spent: $\(totalSpent)"
            updateTableView(animated: true)
        }
        
        // Check if the pick was already selected
        if pickItems[index].isSelected {
            totalSpent -= pickItems[index].athlete.value
            updatePicksTable()
        } else if pickItems[index].athlete.value <= remainingBudget {
            // If not, make sure we have adequate funds to make the pick
            totalSpent += pickItems[index].athlete.value
            updatePicksTable()
        }
        
        // Enable save button if at least 6 athletes were picked
        saveButton.isEnabled = pickCount >= 6
    }
}

// MARK: - Extensions

// This extention houses table view management functions that utilize the diffable data source API
extension MakePicksTableViewController {
    
    // UITableViewDiffableDataSource subclass with custom section headers
    class CustomHeaderDiffableDataSource: UITableViewDiffableDataSource<Int, PickItem> {
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            return "$" + snapshot().sectionIdentifiers[section].description
        }
    }
    
    // MARK: - Other functions
    
    // Create the the data source and specify what to do with a provided cell
    func createDataSource() -> CustomHeaderDiffableDataSource {
        
        return CustomHeaderDiffableDataSource(tableView: tableView) { tableView, indexPath, pickItem in
            
            // Configure the cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "PickCell", for: indexPath) as! PickTableViewCell
            cell.configure(with: pickItem)

            return cell
        }
    }
    
    // Apply a snapshot with updated user pick data
    func updateTableView(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, PickItem>()
        
        // Append the sections
        snapshot.appendSections(sections)
        
        // Append the pick choices for each section
        for (section, picks) in picksBySection {
            snapshot.appendItems(picks, toSection: section)
        }
        
        // Update the data source
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}

