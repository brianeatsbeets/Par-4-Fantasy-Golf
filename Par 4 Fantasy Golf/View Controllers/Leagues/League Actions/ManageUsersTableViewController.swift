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

// MARK: - Protocols

// This protocol allows conformers to be notified of updates to the athletes managed by this view controller
protocol ManageUsersDelegate: AnyObject {
    func addUser(user: User)
    func removeUser(user: User)
}

// MARK: - Main class

// This class/view controller allows for management of the selected league's members
class ManageUsersTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    lazy var dataSource = createDataSource()
    var league: League
    weak var delegate: ManageUsersDelegate?
    let leagueUsersRef: DatabaseReference
    
    // MARK: - Initializers
    
    init?(coder: NSCoder, league: League) {
        self.league = league
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
        updateTableView()
    }
    
    // MARK: - Other functions
    
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
            // TODO: Use a query instead of downloading everything and sorting through
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
                    
                    // If a matching user was found:
                    let matchedUser = matchingUsers.first!
                    
                    // Add the user and user ID to the local league
                    Task {
                        guard let newUser = await User.fetchSingleUser(from: matchedUser.key) else { return }
                        self.league.members.append(newUser)
                        self.delegate?.addUser(user: newUser)
                        self.updateTableView()
                    }
                    self.league.memberIds.append(matchedUser.key)
                    
                    // Add the user's ID to the league and add the league's ID to the user in Firebase
                    self.leagueUsersRef.child(matchedUser.key).setValue(true)
                    usersRef.child(matchedUser.key).child("leagues").child(self.league.id).setValue(true)
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
    
    // MARK: - Diffable data source subclass
    
    // Subclass of UITableViewDiffableDataSource that supports swipe-to-delete
    class SwipeToDeleteDataSource: UITableViewDiffableDataSource<Section, User> {
        
        // MARK: - Properties
        
        var leagueUsersRef = DatabaseReference()
        var usersRef = DatabaseReference()
        var selectedLeague: League!
        var delegate: ManageUsersDelegate?
        
        // MARK: - Other functions
        
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
        
        // Determine behavior when a row is deleted
        override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            guard let user = itemIdentifier(for: indexPath),
                  editingStyle == .delete else { return }
            
            // Remove the user from the league's members in the local data source
            if let membersIndex = selectedLeague.members.firstIndex(where: { $0.id == user.id }),
               let memberIdsIndex = selectedLeague.memberIds.firstIndex(where: { $0 == user.id }) {
                selectedLeague.members.remove(at: membersIndex)
                selectedLeague.memberIds.remove(at: memberIdsIndex)
                delegate?.removeUser(user: user)
            }
            
            // Remove the user's picks from the local data source and Firebase
            selectedLeague.pickIds.removeValue(forKey: user.id)
            selectedLeague.databaseReference.child("pickIds").child(user.id).removeValue()
            
            // Remove the user's id from the league's memberIds and remove the league's id from the user's league ids
            leagueUsersRef.child(user.id).removeValue()
            usersRef.child(user.id).child("leagues").child(selectedLeague.id).removeValue()
            
            // Update the data source
            var snapshot = NSDiffableDataSourceSnapshot<Section, User>()
            snapshot.appendSections(Section.allCases)
            snapshot.appendItems(selectedLeague.members)
            apply(snapshot, animatingDifferences: true)
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
        
        let dataSource = SwipeToDeleteDataSource(tableView: tableView) { tableView, indexPath, user in
            
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
        dataSource.leagueUsersRef = leagueUsersRef
        dataSource.usersRef = Database.database().reference(withPath: "users")
        dataSource.selectedLeague = league
        dataSource.delegate = delegate
        
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
