//
//  ManageUsersTableViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/16/23.
//

// MARK: - Imported libraries

import UIKit
import FirebaseDatabase
import Combine

// MARK: - Protocols

// This protocol allows the ManageUsersTableViewController to be notified when a swipe-to-delete event occurs
protocol ManageUsersSwipeToDeleteDelegate: AnyObject {
    func removeUser(user: User)
}

// MARK: - Main class

// This class/view controller allows for management of the selected league's members
class ManageUsersTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    lazy var dataSource = createDataSource()
    
    var dataStore: DataStore
    let leagueIndex: Int
    var league: League
    var subscription: AnyCancellable?
    
    let leagueUsersRef: DatabaseReference
    
    // MARK: - Initializers
    
    init?(coder: NSCoder, dataStore: DataStore, leagueIndex: Int) {
        self.dataStore = dataStore
        self.leagueIndex = leagueIndex
        league = dataStore.leagues[leagueIndex]
        leagueUsersRef = league.databaseReference.child("memberIds")
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View life cycle functions

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = dataSource
        subscribeToDataStore()
        updateTableView()
    }
    
    // MARK: - Other functions
    
    // Create a subscription for the datastore
    func subscribeToDataStore() {
        subscription = dataStore.$leagues.sink(receiveCompletion: { _ in
            print("Completion")
        }, receiveValue: { [weak self] leagues in
            print("ManageUsersTableVC received updated value for leagues")
            
            // If this view controller has been dismissed, skip assigning a self-referencing value below
            guard let self else { return }

            // Update VC local league variable
            self.league = leagues[self.leagueIndex]
        })
    }
    
    // Display an alert that allows the user to add a new user to the league
    @IBAction func addButtonPressed(_ sender: Any) {
        
        // Create initial alert
        let addUserAlert = UIAlertController(title: "Add User", message: "Enter the user's email address below and tap Search.", preferredStyle: .alert)
        addUserAlert.addTextField()
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        let search = UIAlertAction(title: "Search", style: .default) { _ in
            
            // Grab the user-entered email
            let email = addUserAlert.textFields![0].text
            
            // Search for a user with the provided email unless they're already a league member
            if self.league.members.contains(where: { $0.email == email }) {
                self.displayAlert(title: "User Already Added", message: "The user with the provided email address is already a member of this league.")
            } else {
                self.searchForUser(with: email)
            }
        }
        
        // Add the alert actions
        addUserAlert.addAction(cancel)
        addUserAlert.addAction(search)
        
        // Present the alert
        present(addUserAlert, animated: true)
    }
    
    // Display an alert that allows the user to add a new user to the league
    func searchForUser(with email: String?) {
        
        // Query for a matching user
        let usersRef = Database.database().reference(withPath: "users")
        usersRef.queryOrdered(byChild: "email").queryEqual(toValue: email).observeSingleEvent(of: .value) { [weak self] snapshot in
            
            // Make sure self is still allocated; otherwise, cancel the operation
            guard let self else { return }
            
            // Check if we have a result
            if snapshot.exists() {
                
                // Create a new user from the query result
                guard let childSnapshot = snapshot.children.nextObject() as? DataSnapshot,
                      let newUser = User(snapshot: childSnapshot) else { return }
                
                // Create temporary league copy to avoid updating the data store multiple times
                var updatedLeague = self.dataStore.leagues[self.leagueIndex]
                
                // Add the user to the data store
                updatedLeague.members.append(newUser)
                updatedLeague.memberIds.append(newUser.id)
                
                // Sort the members
                updatedLeague.members = updatedLeague.members.sorted(by: { $0.username < $1.username })
                
                // Save the updated league values to the data store and update the table view
                self.dataStore.leagues[self.leagueIndex] = updatedLeague
                self.updateTableView()
                
                // Add the user's ID to the league and add the league's ID to the user in Firebase
                self.leagueUsersRef.child(newUser.id).setValue(true)
                usersRef.child(newUser.id).child("leagues").child(self.league.id).setValue(true)
            } else {
                
                // If no matching user was not found, alert the user
                self.displayAlert(title: "User Not Found", message: "No user was found with the provided email address.")
            }
        }
    }
    
    // Set the text of the 'Delete' view when swiping-to-delete a cell
    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
         return "Remove"
    }
}

// MARK: - Extensions

// This extension conforms to the ManageUsersSwipeToDeleteDelegate procotol
extension ManageUsersTableViewController: ManageUsersSwipeToDeleteDelegate {
    func removeUser(user: User) {
        
        // Create temporary league copy to avoid updating the data store multiple times
        var updatedLeague = dataStore.leagues[leagueIndex]
        updatedLeague.members.removeAll { $0.id == user.id }
        updatedLeague.memberIds.removeAll { $0 == user.id }
        dataStore.leagues[leagueIndex] = updatedLeague
        
        // Remove the user's picks from the local data source and Firebase
        for tournamentId in league.tournamentIds {
            if let index = league.tournaments.firstIndex(where: { $0.id == tournamentId }) {
                league.tournaments[index].pickIds.removeValue(forKey: user.id)
            }
            Database.database().reference(withPath: "tournaments").child(tournamentId).child("pickIds").child(user.id).removeValue()
        }
        
        // Remove the user's id from the league's memberIds and remove the league's id from the user's league ids
        leagueUsersRef.child(user.id).removeValue()
        Database.database().reference(withPath: "users").child(user.id).child("leagues").child(league.id).removeValue()
        
        updateTableView()
    }
}

// This extention houses table view management functions that utilize the diffable data source API
extension ManageUsersTableViewController {
    
    // MARK: - Diffable data source subclass
    
    // Subclass of UITableViewDiffableDataSource that supports swipe-to-delete
    class SwipeToDeleteDataSource: UITableViewDiffableDataSource<Section, User> {
        
        // MARK: - Properties
        
        var selectedLeague: League!
        weak var swipeToDeleteDelegate: ManageUsersSwipeToDeleteDelegate?
        weak var manageUsersViewController: ManageUsersTableViewController?
        
        // MARK: - Other functions
        
        // Enable swipe-to-delete
        override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            
            // Check if selected user is league owner; if so, disable swipe-to-delete
            if let user = itemIdentifier(for: indexPath),
               user.id != selectedLeague.creator {
                return true
            } else {
                return false
            }
        }
        
        // Determine behavior when a row is deleted
        override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            guard let user = itemIdentifier(for: indexPath),
                  editingStyle == .delete else { return }
            
            let removeUserAlert = UIAlertController(title: "Are you sure?", message: "This user and their records for this league will be permanently deleted.", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            let okAction = UIAlertAction(title: "Remove User", style: .destructive) { _ in
                
                removeUserAlert.dismiss(animated: true)
                
                // Alert delegates of removed user
                self.swipeToDeleteDelegate?.removeUser(user: user)
            }
            
            removeUserAlert.addAction(cancelAction)
            removeUserAlert.addAction(okAction)
            
            if let manageUsersViewController = manageUsersViewController {
                manageUsersViewController.present(removeUserAlert, animated: true)
            }
        }
    }
    
    // MARK: - Section enum
    
    // This enum declares table view sections
    enum Section: CaseIterable {
        case one
    }
    
    // MARK: - Other functions
    
    // Create the the data source and specify what to do with a provided cell
    func createDataSource() -> SwipeToDeleteDataSource {
        
        let dataSource = SwipeToDeleteDataSource(tableView: tableView) { [weak self] tableView, indexPath, user in
            
            // Configure the cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath)
            
            var config = cell.defaultContentConfiguration()
            config.text = user.username
            config.secondaryText = user.email
            
            if let creator = self?.league.creator,
               user.id == creator {
                config.text! += " (owner)"
            }
            cell.contentConfiguration = config

            return cell
        }
        
        // Variables that allow the custom data source to access the current league's firebase database reference to delete data
        dataSource.selectedLeague = league
        dataSource.swipeToDeleteDelegate = self
        dataSource.manageUsersViewController = self
        
        return dataSource
    }
    
    // Apply a snapshot with updated user data
    func updateTableView(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, User>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(league.members)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}
