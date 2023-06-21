//
//  LeaguesTableViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/1/23.
//

// TODO: Remove this class and view controller

// MARK: - Imported libraries

import UIKit
import FirebaseAuth
import FirebaseDatabase

// MARK: - Main class

// This class/view controller displays available leagues
class LeaguesTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    lazy var dataSource = createDataSource()
    var minimalLeagues = [MinimalLeague]()
    let leagueIdsRef = Database.database().reference(withPath: "leagueIds")
    let userLeaguesRef = Database.database().reference(withPath: "users/\(Auth.auth().currentUser!.uid)/leagues")
    
    // MARK: - View life cycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = dataSource
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        displayLoadingIndicator(animated: false)
        
        // Fetch initial league data and update the table view
        fetchMinimalLeagueData() {
            self.dismissLoadingIndicator(animated: true)
            self.updateTableView()
        }
    }
    
    // MARK: - Other functions
    
    // Fetch league data from the leagueIds tree and store it
    func fetchMinimalLeagueData(completion: @escaping () -> Void) {
        
        // Fetch user league Ids
        userLeaguesRef.observeSingleEvent(of: .value) { snapshot in
            guard let userLeagueIdValues = snapshot.value as? [String: Bool] else {
                completion()
                return
            }
            
            let userLeagueIds = userLeagueIdValues.map { $0.key }
            
            // Fetch minimal leagues from user league Ids
            Task {
                self.minimalLeagues = await MinimalLeague.fetchMultipleLeagues(from: userLeagueIds)
                
                // Sort leagues
                self.minimalLeagues = self.minimalLeagues.sorted(by: { $0.name > $1.name})
                completion()
            }
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
        
        let minimalLeague = MinimalLeague(league: league)
        
        Task {
            // Save the league to the leagues tree in Firebase
            try await league.databaseReference.setValue(league.toAnyObject())
            
            // Save the league to the leagueIds tree in Firebase
            try await leagueIdsRef.child(league.id).setValue(minimalLeague.toAnyObject())
            
            // Save the league to the league members' data
            for id in league.memberIds {
                try await Database.database().reference(withPath: "users").child(id).child("leagues").child(league.id).setValue(true)
            }
            
            // Save the minimal league to the local data source
            minimalLeagues.append(minimalLeague)
            minimalLeagues = minimalLeagues.sorted(by: { $0.name > $1.name})
            
            updateTableView()
            
            dismissLoadingIndicator(animated: true)
        }
    }
    
    // Segue to LeagueDetailViewController with full league data
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
//        displayLoadingIndicator(animated: true)
//        
//        // Fetch the league data from the tapped league's id
//        Task {
//            guard let minimalLeague = dataSource.itemIdentifier(for: indexPath),
//                  var league = await League.fetchSingleLeague(from: minimalLeague.id) else { return }
//            
//            // Fetch the league members
//            league.members = await User.fetchMultipleUsers(from: league.memberIds)
//            
//            guard let destinationViewController = storyboard?.instantiateViewController(identifier: "LeagueDetail", creator: { coder in
//                LeagueDetailTableViewController(coder: coder, league: league)
//            }) else { return }
//            
//            // Deselect the row and push the league details view controller while passing the full league data
//            tableView.deselectRow(at: indexPath, animated: true)
//            self.navigationController?.pushViewController(destinationViewController, animated: true)
//        }
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
    func createDataSource() -> UITableViewDiffableDataSource<Section, MinimalLeague> {
        
        return UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, league in
            
            // Configure the cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "LeagueCell", for: indexPath) as! LeagueTableViewCell
            cell.configure(with: league)
            
            return cell
        }
    }
    
    // Apply a snapshot with updated league data
    func updateTableView(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, MinimalLeague>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(minimalLeagues)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}
