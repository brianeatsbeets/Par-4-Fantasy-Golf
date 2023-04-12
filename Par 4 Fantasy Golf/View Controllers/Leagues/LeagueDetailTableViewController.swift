//
//  LeagueDetailTableViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 4/5/23.
//

// MARK: - Imported libraries

import UIKit
import FirebaseAuth
import FirebaseDatabase

// MARK: - Main class

// This class/view controller displays details and tournaments for the selected league
class LeagueDetailTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    @IBOutlet var leagueActionsBarButtonItemGroup: UIBarButtonItemGroup!
    
    lazy var dataSource = createDataSource()
    var league: League
    let currentFirebaseUser = Auth.auth().currentUser!
    var firstLoad = true
    var calendarEvents = [CalendarEvent]()
    var denormalizedTournaments = [MinimalTournament]()
    let tournamentIdsRef = Database.database().reference(withPath: "tournamentIds")
    
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
        
        tableView.dataSource = dataSource
        title = league.name
        
        // If the current user is not the league owner, hide administrative actions
        if league.creator != currentFirebaseUser.email {
            leagueActionsBarButtonItemGroup.isHidden = true
        }
        
        // Fetch league member data
        Task {
            league.members = await User.fetchMultipleUsers(from: self.league.memberIds)
            updateTableView()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Fetch initial tournament data and update the table view
        fetchDenormalizedTournamentData() {
            self.updateTableView()
        }
    }
    
    // MARK: - Other functions
    
    // Fetch tournament data from the tournamentIds tree and store it
    func fetchDenormalizedTournamentData(completion: @escaping () -> Void) {
        
        // Remove all existing tournament data
        self.denormalizedTournaments.removeAll()
        
        // Fetch the data
        tournamentIdsRef.observeSingleEvent(of: .value) { snapshot in
            
            // Verify that the received data produces valid DenormalizedTournaments, and if it does, append them
            for childSnapshot in snapshot.children {
                guard let childSnapshot = childSnapshot as? DataSnapshot,
                      let tournament = MinimalTournament(snapshot: childSnapshot) else {
                    print("Failed to create denormalized tournament")
                    continue
                }
                
                self.denormalizedTournaments.append(tournament)
            }
            
            // Sort tournament
            self.denormalizedTournaments = self.denormalizedTournaments.sorted(by: { $0.name < $1.name})
            
            // Call completion handler
            completion()
        }
    }
    
    // Remove league data and user associations
    @IBAction func deleteLeaguePressed(_ sender: Any) {
        let deleteLeagueAlert = UIAlertController(title: "Are you sure?", message: "All of the league data will be permenantly deleted.", preferredStyle: .alert)
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        let confirm = UIAlertAction(title: "Delete League", style: .destructive) { [unowned deleteLeagueAlert] _ in
            
            // Dismiss the current alert
            deleteLeagueAlert.dismiss(animated: true)
            
            // Remove the league from each user's leagues
            for user in self.league.members {
                user.databaseReference.child("leagues").child(self.league.id).removeValue()
            }
            
            // Remove the league data from the leagues and leagueIds trees
            self.league.databaseReference.removeValue()
            Database.database().reference().child("leagueIds").child(self.league.id).removeValue()
            
            // Return to LeaguesTableViewController
            self.navigationController?.popViewController(animated: true)
        }
        
        deleteLeagueAlert.addAction(cancel)
        deleteLeagueAlert.addAction(confirm)
        
        present(deleteLeagueAlert, animated: true)
    }
    
    // MARK: - Navigation
    
    // Pass league data to SelectEventTableViewController
    @IBSegueAction func segueToCreateTournament(_ coder: NSCoder) -> SelectEventTableViewController? {
        return SelectEventTableViewController(coder: coder, events: calendarEvents)
    }
    
    // Pass league data to ManageUsersTableViewController
    @IBSegueAction func segueToManageUsers(_ coder: NSCoder) -> ManageUsersTableViewController? {
        guard let manageUsersViewController = ManageUsersTableViewController(coder: coder, league: league) else { return nil }
        manageUsersViewController.delegate = self
        return manageUsersViewController
    }
    
    // Segue to TournamentDetailViewController with full tournament data
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Fetch the stored tournament data from firebase
        Task {
            guard let denormalizedTournament = dataSource.itemIdentifier(for: indexPath),
                  let tournament = await Tournament.fetchSingleTournament(from: denormalizedTournament.id),
                  let destinationViewController = storyboard?.instantiateViewController(identifier: "TournamentDetail", creator: { coder in
                      TournamentDetailTableViewController(coder: coder, league: self.league, tournament: tournament)
                  }) else { return }
            
            // Deselect the row and push the league details view controller while passing the full league data
            tableView.deselectRow(at: indexPath, animated: true)
            navigationController?.pushViewController(destinationViewController, animated: true)
        }
    }
    
    // Handle the incoming new tournament data
    @IBAction func unwindFromCreateTournament(segue: UIStoryboardSegue) {
        
        // Check that we have new tournament data to parse
        guard segue.identifier == "unwindCreateTournament",
              let sourceViewController = segue.source as? CreateTournamentTableViewController,
              let newTournament = sourceViewController.tournament else { return }
        
        // Save the tournament to the local data source
        league.tournamentIds.append(newTournament.id)
        league.tournaments.append(newTournament)
        
        // Save the denormalized tournament to the local data source and sort
        let denormalizedTournament = MinimalTournament(tournament: newTournament)
        denormalizedTournaments.append(denormalizedTournament)
        denormalizedTournaments = denormalizedTournaments.sorted(by: { $0.name < $1.name})
        
        // Save the tournament to Firebase
        
        // League tournament Ids
        league.databaseReference.child("tournamentIds").child(newTournament.id).setValue(true)
        
        // Tournaments tree
        newTournament.databaseReference.setValue(newTournament.toAnyObject())
        
        // TournamentIds tree
        tournamentIdsRef.child(newTournament.id).setValue(denormalizedTournament.toAnyObject())
        
        updateTableView()
    }
}

// MARK: - Extensions

// This extention houses table view management functions that utilize the diffable data source API
extension LeagueDetailTableViewController {
    
    // MARK: - Section enum
    
    // This enum declares table view sections
    enum Section: CaseIterable {
        case one
    }
    
    // MARK: - Other functions
    
    // Create the the data source and specify what to do with a provided cell
    func createDataSource() -> UITableViewDiffableDataSource<Section, MinimalTournament> {
        
        return UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, denormalizedTournament in
            
            // Configure the cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "LeagueDetailCell", for: indexPath) as! TournamentTableViewCell
            cell.configure(with: denormalizedTournament)

            return cell
        }
    }
    
    // Apply a snapshot with updated league data
    func updateTableView(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, MinimalTournament>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(denormalizedTournaments)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}

// This extention conforms to the ManageUsersDelegate protocol
extension LeagueDetailTableViewController: ManageUsersDelegate {
    
    // Add a new user
    func addUser(user: User) {
        league.members.append(user)
        league.memberIds.append(user.id)
    }
    
    // Remove an existing user
    func removeUser(user: User) {
        league.members.removeAll { $0.id == user.id }
        league.memberIds.removeAll { $0 == user.id }
    }
}
