//
//  LeaguesTableViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/1/23.
//

// TODO: Figure out why leagues sometimes update after returning from league details (maybe related to sorting?) - is this still an issue?

// MARK: - Imported libraries

import UIKit
import FirebaseAuth
import FirebaseDatabase

// MARK: - Main class

// This class/view controller displays available leagues
class LeaguesTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    @IBOutlet var leaguesDisplaySwitch: UISwitch!
    
    lazy var dataSource = createDataSource()
    var denormalizedLeagues = [DenormalizedLeague]()
    let leagueIdsRef = Database.database().reference(withPath: "leagueIds")
    let userLeaguesRef = Database.database().reference(withPath: "users/\(Auth.auth().currentUser!.uid)/leagues")
    
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
        
        // Only display joined leagues
        if !leaguesDisplaySwitch.isOn {
            
            // Remove all existing league data
            self.denormalizedLeagues.removeAll()
            
            // Fetch user league Ids
            userLeaguesRef.observeSingleEvent(of: .value) { snapshot in
                guard let userLeagueIdValues = snapshot.value as? [String: Bool] else { print("Boo"); return }
                let userLeagueIds = userLeagueIdValues.map { $0.key }
                
                // Fetch denormalized leagues from user league Ids
                Task {
                    self.denormalizedLeagues = await DenormalizedLeague.fetchMultipleLeagues(from: userLeagueIds)
                    
                    // Sort leagues
                    self.denormalizedLeagues = self.denormalizedLeagues.sorted(by: { $0.name > $1.name})
                    completion()
                }
            }
        } else { // Display all leagues
            
            // Remove all existing league data
            self.denormalizedLeagues.removeAll()
            
            // Fetch the data
            leagueIdsRef.observeSingleEvent(of: .value) { snapshot in
                
                // Verify that the received data produces valid DenormalizedLeagues, and if it does, append them
                for childSnapshot in snapshot.children {
                    guard let childSnapshot = childSnapshot as? DataSnapshot,
                          let league = DenormalizedLeague(snapshot: childSnapshot) else {
                        print("Failed to create denormalized league")
                        continue
                    }
                    
                    self.denormalizedLeagues.append(league)
                }
                
                // Sort leagues
                self.denormalizedLeagues = self.denormalizedLeagues.sorted(by: { $0.name > $1.name})
                completion()
            }
        }
    }
    
    // Switch between viewing joined leagues and all leagues
    @IBAction func leaguesDisplaySwitchToggled() {
        fetchDenormalizedLeagueData {
            self.updateTableView()
        }
    }
    
    // MARK: - Navigation
    
    // Handle the incoming new league data
    // TODO: Just update the denormalizedLeagues array and updateTableView() locally instead of fetching them from firebase
    @IBAction func unwindFromCreateLeague(segue: UIStoryboardSegue) {
        
        // Check that we have new league data to parse
        guard segue.identifier == "createLeagueUnwind",
              let sourceViewController = segue.source as? CreateLeagueTableViewController,
              let league = sourceViewController.league
        else { return }
        
        // Save the league to the leagues tree in Firebase
        league.databaseReference.setValue(league.toAnyObject())
        
        // Save the league to the leagueIds tree in Firebase
        let denormalizedLeague = DenormalizedLeague(id: league.id, name: league.name)
        leagueIdsRef.child(league.id).setValue(denormalizedLeague.toAnyObject())
        
        // Save the league to the league members' data
        for user in league.members {
            user.databaseReference.child("leagues").child(league.id).setValue(true)
        }
        
        // Fetch league data and update the table view
        fetchDenormalizedLeagueData() {
            self.updateTableView()
        }
    }
    
    // Segue to LeagueDetailViewController with full league data
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Fetch the league data from the tapped league's id
        Task {
            guard let denormalizedLeague = dataSource.itemIdentifier(for: indexPath),
                  let league = await League.fetchSingleLeague(from: denormalizedLeague.id),
                  let destinationViewController = storyboard?.instantiateViewController(identifier: "LeagueDetail", creator: { coder in
                      LeagueDetailTableViewController(coder: coder, league: league)
                  }) else { return }
            
            // Deselect the row and push the league details view controller while passing the full league data
            tableView.deselectRow(at: indexPath, animated: true)
            navigationController?.pushViewController(destinationViewController, animated: true)
        }
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
        snapshot.appendItems(denormalizedLeagues)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}
