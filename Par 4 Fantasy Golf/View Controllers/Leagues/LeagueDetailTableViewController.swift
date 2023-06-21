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
    
    let currentFirebaseUser = Auth.auth().currentUser!
    var firstLoad = true
    var calendarEvents = [CalendarEvent]()
    var subscription: AnyCancellable?
    
    // TODO: Remove this
    weak var delegate: LeagueDataSourceDelegate?
    
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
        
        title = league.name + " Tournaments"
        
        // If the current user is not the league owner, hide administrative actions
        if league.creator != currentFirebaseUser.uid {
            leagueActionsBarButtonItemGroup.isHidden = true
        }
        
        tableView.dataSource = dataSource
        updateTableView()
        
        subscribe()
    }
    
    // TODO: Can we use viewWillAppear?
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateTableView(animated: false)
    }
    
    // MARK: - Other functions
    
    // Create a subscription for the datastore
    func subscribe() {
        subscription = dataStore.$leagues.sink(receiveCompletion: { _ in
            print("Completion")
        }, receiveValue: { leagues in
            print("LeagueDetailTableVC received updated value for leagues")
            
            // Update VC local league variable
            self.league = leagues[self.leagueIndex]
        })
    }
    
    // Remove league data and user associations
    @IBAction func deleteLeaguePressed(_ sender: Any) {
        let deleteLeagueAlert = UIAlertController(title: "Are you sure?", message: "All of the league data will be permenantly deleted.", preferredStyle: .alert)
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        let confirm = UIAlertAction(title: "Delete League", style: .destructive) { [unowned deleteLeagueAlert] _ in
            
            // Dismiss the current alert
            deleteLeagueAlert.dismiss(animated: true)
            
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
        guard let manageUsersViewController = ManageUsersTableViewController(coder: coder, league: dataStore.leagues[leagueIndex]) else { return nil }
        manageUsersViewController.delegate = self
        return manageUsersViewController
    }
    
    // Segue to TournamentDetailViewController with full tournament data
    // TODO: Revert back to segue action instead of manually pushing
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let tournament = dataSource.itemIdentifier(for: indexPath),
              let destinationViewController = storyboard?.instantiateViewController(identifier: "TournamentDetail", creator: { coder in
                  TournamentDetailTableViewController(coder: coder, league: self.league, tournament: tournament)
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
              let newTournament = sourceViewController.tournament else { return }
        
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
        //TODO: Pull tournament removal code into here from TournamentDetailTableViewController
        //updateTableView()
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
    func createDataSource() -> UITableViewDiffableDataSource<Section, Tournament> {
        
        return UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, tournament in
            
            // Configure the cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "LeagueDetailCell", for: indexPath) as! TournamentTableViewCell
            cell.configure(with: tournament)

            return cell
        }
    }
    
    // Apply a snapshot with updated league data
    func updateTableView(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Tournament>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(league.tournaments)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}

// This extention conforms to the ManageUsersDelegate protocol
extension LeagueDetailTableViewController: ManageUsersDelegate {
    
    // Add a new user
    func addUser(user: User) {
        dataStore.leagues[leagueIndex].members.append(user)
        dataStore.leagues[leagueIndex].memberIds.append(user.id)
    }
    
    // Remove an existing user
    func removeUser(user: User) {
        dataStore.leagues[leagueIndex].members.removeAll { $0.id == user.id }
        dataStore.leagues[leagueIndex].memberIds.removeAll { $0 == user.id }
    }
}
