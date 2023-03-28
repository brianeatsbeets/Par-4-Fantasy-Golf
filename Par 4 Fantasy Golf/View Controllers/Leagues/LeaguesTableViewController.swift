//
//  LeaguesTableViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/1/23.
//

// TODO: Figure out why leagues sometimes update after returning from league details (maybe related to sorting?)

// MARK: - Imported libraries

import UIKit
import FirebaseAuth
import FirebaseDatabase

// MARK: - Main class

// This class/view controller displays available leagues
class LeaguesTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    lazy var dataSource = createDataSource()
    var leagues = [DenormalizedLeague]()
    let leagueIdsRef = Database.database().reference(withPath: "leagueIds")
    
    // MARK: - View life cycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = dataSource
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Fetch initial league data and update the table view
        fetchDenormalizedLeagueData() {
            self.updateTableView()
        }
    }
    
    // MARK: - Other functions
    
    // Fetch league data from the leagueIds tree and store it
    func fetchDenormalizedLeagueData(completion: @escaping () -> Void) {
        
        // Fetch the data
        leagueIdsRef.observeSingleEvent(of: .value) { snapshot in
            
            // Remove all existing league data
            self.leagues.removeAll()
            
            // Verify that the received data produces valid DenormalizedLeagues, and if it does, append them
            for childSnapshot in snapshot.children {
                guard let childSnapshot = childSnapshot as? DataSnapshot,
                      let league = DenormalizedLeague(snapshot: childSnapshot) else {
                    print("Failed to create denormalized league")
                    continue
                }
                
                self.leagues.append(league)
            }
            
            completion()
        }
    }
    
    // MARK: - Navigation
    
    // Handle the incoming new league data
    @IBAction func unwindFromCreateLeague(segue: UIStoryboardSegue) {
        
        // Check that we have new league data to parse
        guard segue.identifier == "createLeagueUnwind",
              let sourceViewController = segue.source as? CreateLeagueTableViewController,
              let league = sourceViewController.league
        else { return }
        
        // Save the league to the leagues tree in Firebase
        league.databaseReference.setValue(league.toAnyObject())
        
        // Save the league to the leagueIds tree in Firebase
        let denormalizedLeague = DenormalizedLeague(id: league.id, name: league.name, startDate: league.startDate)
        leagueIdsRef.child(league.id).setValue(denormalizedLeague.toAnyObject())
        
        // Save the league to the league members' data
        for user in league.members {
            user.databaseReference.child("leagues").child(league.id).setValue(true)
        }
    }
    
    // Prepare league data to send to LeagueDetailViewController
    @IBSegueAction func segueToLeagueDetails(_ coder: NSCoder, sender: Any?) -> LeagueDetailTableViewController? {
        
        // Check to see if a cell was tapped
        guard let cell = sender as? UITableViewCell,
              let indexPath = tableView.indexPath(for: cell),
              let denormalizedLeague = dataSource.itemIdentifier(for: indexPath) else { return nil }
        
        // If so, pass the tapped league data
        return LeagueDetailTableViewController(coder: coder, denormalizedLeague: denormalizedLeague)
    }
}

// MARK: - Extensions

// This extention houses table view management functions that utilize the diffable data source API
extension LeaguesTableViewController {
    
    // MARK: - Section enum
    
    // This enum declares table view sections
    enum Section: CaseIterable {
        case one
    }
    
    // MARK: - Other functions
    
    // Create the the data source and specify what to do with a provided cell
    func createDataSource() -> UITableViewDiffableDataSource<Section, DenormalizedLeague> {
        
        return UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, league in
            
            // Configure the cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "LeagueCell", for: indexPath) as! LeagueTableViewCell
            cell.configure(with: league)
            
            return cell
        }
    }
    
    // Apply a snapshot with updated league data
    func updateTableView(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, DenormalizedLeague>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(leagues)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}
