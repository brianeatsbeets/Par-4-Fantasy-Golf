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
import Combine

// MARK: - Main class

// This class/view controller displays details and tournaments for the selected league
class LeagueDetailTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    @IBOutlet var leagueActionsBarButtonItemGroup: UIBarButtonItemGroup!
    
    lazy var dataSource = createDataSource()
    
    /*
     * General data workflow:
     * - Pass and subscribe to dataStore
     * - Create VC local copy of applicable data (properties of dataStore are structs, so copies are value copies, not reference)
     * - When referencing applicable data, use local copy
     * - When modifying applicable data, use dataStore
     * -- The subscription will update the local copy to match the dataStore
     */
    var dataStore: DataStore
    let leagueIndex: Int
    var league: League
    var subscription: AnyCancellable?
    
    let currentFirebaseUser = Auth.auth().currentUser!
    var firstLoad = true
    var calendarEvents = [CalendarEvent]()
    
    // MARK: - Initializers
    
    init?(coder: NSCoder, dataStore: DataStore, leagueIndex: Int) {
        self.dataStore = dataStore
        self.leagueIndex = leagueIndex
        league = dataStore.leagues[leagueIndex]
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View life cycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // If the current user is not the league owner, hide administrative actions
        if league.creator != currentFirebaseUser.uid {
            leagueActionsBarButtonItemGroup.isHidden = true
        }
        
        tableView.dataSource = dataSource
        subscribeToDataStore()
        updateTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateTableView(animated: false)
    }
    
    // MARK: - Other functions
    
    // Create a subscription for the datastore
    func subscribeToDataStore() {
        subscription = dataStore.$leagues.sink(receiveCompletion: { _ in
            print("Completion")
        }, receiveValue: { [weak self] leagues in
            print("LeagueDetailTableVC received updated value for leagues")
            
            // If this view controller has been dismissed, skip assigning a self-referencing value below
            guard let self else { return }
            
            // Update VC local league variable
            self.league = leagues[self.leagueIndex]
            self.league.tournaments = self.league.tournaments.sorted { $0.startDate > $1.startDate }
        })
    }
    
    // Remove league data and user associations
    @IBAction func deleteLeaguePressed(_ sender: Any) {
        let deleteLeagueAlert = UIAlertController(title: "Are you sure?", message: "All of the league data will be permenantly deleted.", preferredStyle: .alert)
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        let confirm = UIAlertAction(title: "Delete League", style: .destructive) { _ in
            
            // Cancel the subscription early to prevent updating the local league variable with league data that no longer exists
            self.subscription?.cancel()
            
            // Return to LeaguesTableViewController
            self.performSegue(withIdentifier: "deleteLeagueUnwind", sender: nil)
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
        return ManageUsersTableViewController(coder: coder, dataStore: dataStore, leagueIndex: leagueIndex)
    }
    
    // Segue to TournamentDetailViewController with full tournament data
    // TODO: Revert back to segue action instead of manually pushing
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let tournament = dataSource.itemIdentifier(for: indexPath),
              let tournamentIndex = self.dataStore.leagues[self.leagueIndex].tournaments.firstIndex(where: { $0.id == tournament.id }),
              let destinationViewController = storyboard?.instantiateViewController(identifier: "TournamentDetail", creator: { coder in
                  TournamentDetailTableViewController(coder: coder, dataStore: self.dataStore, leagueIndex: self.leagueIndex, tournamentIndex: tournamentIndex)
              }) else { return }
        
        // Deselect the row and push the league details view controller while passing the full league data
        tableView.deselectRow(at: indexPath, animated: true)
        self.navigationController?.pushViewController(destinationViewController, animated: true)
    }
    
    // Handle the incoming new tournament data
    @IBAction func unwindFromCreateTournament(segue: UIStoryboardSegue) {
        
        // Check that we have new tournament data to parse
        guard segue.identifier == "unwindCreateTournament",
              let sourceViewController = segue.source as? CreateTournamentTableViewController,
              var newTournament = sourceViewController.tournament else { return }
        
        // Calculate tournament standings
        newTournament.standings = newTournament.calculateStandings(leagueMembers: league.members)
        
        // Save the tournament to the data store
        dataStore.leagues[leagueIndex].tournaments.append(newTournament)
        
        // Save the tournament to Firebase
        
        // League tournament Ids
        league.databaseReference.child("tournamentIds").child(newTournament.id).setValue(true)
        
        // Tournaments tree
        newTournament.databaseReference.setValue(newTournament.toAnyObject())
        
        dismissLoadingIndicator(animated: true)
        
        updateTableView()
    }
    
    // Handle the incoming new tournament data
    @IBAction func unwindFromDeleteTournament(segue: UIStoryboardSegue) {
        guard segue.identifier == "unwindDeleteTournament",
              let sourceViewController = segue.source as? TournamentDetailTableViewController else { return }
        
        let tournament = sourceViewController.tournament
        
        // Remove the tournament from the data store
        dataStore.leagues[leagueIndex].tournaments.removeAll { $0.id == tournament.id }
        
        // Remove the tournament data from the tournaments tree
        tournament.databaseReference.removeValue()
        
        // Remove the tournament data from the league tournamentIds tree
        league.databaseReference.child("tournamentIds").child(tournament.id).removeValue()
        
        // TODO: Throws warning if animated parameter is true: UITableView was told to layout its visible cells and other contents without being in the view hierarchy
        updateTableView()
    }
}

// MARK: - Extensions

// This extention houses table view management functions that utilize the diffable data source API
extension LeagueDetailTableViewController {
    
    // UITableViewDiffableDataSource subclass with custom section headers
    class CustomHeaderDiffableDataSource: UITableViewDiffableDataSource<Section, Tournament> {
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            return snapshot().sectionIdentifiers[section].rawValue
        }
    }
    
    // MARK: - Section enum
    
    // This enum declares table view sections
    enum Section: String, CaseIterable, Hashable {
        case live = "Live"
        case scheduled = "Scheduled"
        case completed = "Completed"
    }
    
    // MARK: - Other functions
    
    // Create the the data source and specify what to do with a provided cell
    func createDataSource() -> CustomHeaderDiffableDataSource {
        
        return CustomHeaderDiffableDataSource(tableView: tableView) { tableView, indexPath, tournament in
            
            // Configure the cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "LeagueDetailCell", for: indexPath) as! TournamentTableViewCell
            cell.configure(with: tournament)

            return cell
        }
    }
    
    // Apply a snapshot with updated league data
    func updateTableView(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Tournament>()
        
        // Compile the tournaments based on status
        let liveTournaments = league.tournaments.filter({ $0.status == .live })
        let scheduledTournaments = league.tournaments.filter({ $0.status == .scheduled })
        let completedTournaments = league.tournaments.filter({ $0.status == .completed })
        
        // Append the live section and live tournaments, if any
        if !liveTournaments.isEmpty {
            snapshot.appendSections([.live])
            snapshot.appendItems(liveTournaments, toSection: .live)
        }
        
        // Append the scheduled section and scheduled tournaments, if any
        if !scheduledTournaments.isEmpty {
            snapshot.appendSections([.scheduled])
            snapshot.appendItems(scheduledTournaments, toSection: .scheduled)
        }
        
        // Append the completed section and completed tournaments, if any
        if !completedTournaments.isEmpty {
            snapshot.appendSections([.completed])
            snapshot.appendItems(completedTournaments, toSection: .completed)
        }
        
        // Apply the snapshot
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}
