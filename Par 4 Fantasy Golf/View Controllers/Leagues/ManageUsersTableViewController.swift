//
//  ManageUsersTableViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/16/23.
//

// TODO: Add support for swipe-to-delete

// MARK: - Imported libraries

import UIKit
import FirebaseDatabase

// MARK: - Main class

// This class/view controller allows for management of the selected league's members
class ManageUsersTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    lazy var dataSource = createDataSource()
    fileprivate var league: League
    
    let leagueUsersRef: DatabaseReference
    var refObservers: [DatabaseHandle] = []
    
    // MARK: - Initializers
    
    init?(coder: NSCoder, league: League) {
        self.league = league
        leagueUsersRef = Database.database().reference(withPath: "leagues/" + self.league.id.uuidString + "/memberIds")
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View life cycle functions

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = dataSource
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create league data observer
        createLeagueUsersObserver()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Remove all observers
        refObservers.forEach(leagueUsersRef.removeObserver(withHandle:))
        refObservers = []
    }
    
    // MARK: - Other functions
    
    // Create the reference observer for league users
    func createLeagueUsersObserver() {
        
        // Observe league users
        let refHandle = leagueUsersRef.observe(.value) { snapshot in
            
            // Fetch updated league users
            guard let leagueUserIdsDict = snapshot.value as? [String: Bool] else {
                print("Error fetching league users")
                return
            }
            
            // Get array from disctionary
            let leagueUserIds = leagueUserIdsDict.map { $0.key }
            
            // Fetch users via task and update the table view when finished
            Task {
                self.league.members = await User.fetchMultipleUsers(from: leagueUserIds)
                self.updateTableView()
            }
        }
        
        refObservers.append(refHandle)
    }
    
    // Display an alert that allows the user to add a new user to the league
    @IBAction func addButtonPressed(_ sender: Any) {
        
        // Create initial alert
        let addUserAlert = UIAlertController(title: "Add User", message: "Enter the user's email address below and tap Search.", preferredStyle: .alert)
        addUserAlert.addTextField()
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        let search = UIAlertAction(title: "Search", style: .default) { [unowned addUserAlert] _ in
            
            // Grab the user-entered email
            let email = addUserAlert.textFields![0].text
            
            // Dismiss the current alert
            addUserAlert.dismiss(animated: true)
            
            // Fetch the users list
            // TODO: This would be more efficient if email was the ID for a user instead of a UUID from firebase
            let usersRef = Database.database().reference(withPath: "users")
            usersRef.observeSingleEvent(of: .value) { snapshot in
                guard let usersList = snapshot.value as? [String:[String: AnyObject]] else {
                    print("Error getting users list")
                    return
                }
                
                // Check for a user with a matching email address
                let matchingUsers = usersList.filter { $0.value["email"] as? String == email }
                
                if matchingUsers.isEmpty {
                    
                    // If no matching user was not found, alert the user
                    let userNotFoundAlert = UIAlertController(title: "User Not Found", message: "No user was found with the provided email address.", preferredStyle: .alert)
                    let ok = UIAlertAction(title: "OK", style: .default)
                    userNotFoundAlert.addAction(ok)
                    self.present(userNotFoundAlert, animated: true)
                } else {
                    
                    // If a matching user was found, add the user to the league and add the league to the user's data
                    let matchedUser = matchingUsers.first!
                    let leagueMembersRef = Database.database().reference(withPath: "leagues/\(self.league.id)/memberIds")
                    leagueMembersRef.child(matchedUser.key).setValue(true)
                    usersRef.child(matchedUser.key).child("leagues").child(self.league.id.uuidString).setValue(true)
                }
            }
            
        }
        
        // Add the alert actions
        addUserAlert.addAction(cancel)
        addUserAlert.addAction(search)
        
        // Present the alert
        present(addUserAlert, animated: true)
    }
}

// MARK: - Extensions

// This extention houses table view management functions that utilize the diffable data source API
extension ManageUsersTableViewController {
    
    // Subclass of UITableViewDiffableDataSource that supports swipe-to-delete
    class SwipeToDeleteDataSource: UITableViewDiffableDataSource<Section, User> {
        
        var leagueUsersRef = DatabaseReference()
        var usersRef = DatabaseReference()
        var selectedLeague: League!
        
        // Enable swipe-to-delete
        override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            
            // Check if selected user is league owner; if so, disable swipe-to-delete
            if let user = itemIdentifier(for: indexPath),
               user.email != selectedLeague.creator {
                return true
            } else {
                return false
            }
        }
        
        override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            guard let user = itemIdentifier(for: indexPath) else { return }
            
            // Remove the user's id from the league's memberIds and remove the league's id from the user's league ids
            leagueUsersRef.child(user.id).removeValue()
            usersRef.child(user.id).child("leagues").child(selectedLeague.id.uuidString).removeValue()
        }
    }
    
    // This enum declares table view sections
    enum Section: CaseIterable {
        case one
    }
    
    // Create the the data source and specify what to do with a provided cell
    func createDataSource() -> SwipeToDeleteDataSource {
        
        var dataSource = SwipeToDeleteDataSource(tableView: tableView) { tableView, indexPath, user in
            
            // Configure the cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath)
            
            var config = cell.defaultContentConfiguration()
            config.text = user.email
            if user.email == self.league.creator {
                config.text! += " (owner)"
            }
            cell.contentConfiguration = config

            return cell
        }
        
        // Variables that allow the custom data source to access the current league's firebase database reference to delete data
        dataSource.leagueUsersRef = Database.database().reference(withPath: "leagues/" + self.league.id.uuidString + "/memberIds")
        dataSource.usersRef = Database.database().reference(withPath: "users")
        dataSource.selectedLeague = self.league
        
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
