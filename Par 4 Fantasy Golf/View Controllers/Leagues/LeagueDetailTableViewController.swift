//
//  LeagueDetailTableViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/3/23.
//

// MARK: - Imported libraries

import UIKit
import FirebaseDatabase

// MARK: - Main class

// This class/view controller displays details for the selected league
class LeagueDetailTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    lazy var dataSource = createDataSource()
    var league: League
    var users = [User]()
    
    let leagueRef: DatabaseReference
    var refObservers: [DatabaseHandle] = []
    
    // MARK: - Initializers
    
    init?(coder: NSCoder, league: League) {
        self.league = league
        self.leagueRef = Database.database().reference(withPath: "leagues/" + league.id.uuidString)
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
        
        updateTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        createLeagueDataObserver()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Remove all observers
        refObservers.forEach(leagueRef.removeObserver(withHandle:))
        refObservers = []
    }
    
    // MARK: - Other functions
    
    // Create the reference observer for league data
    func createLeagueDataObserver() {
        
        // Observe league data
        let refHandle = leagueRef.observe(.value) { snapshot in
            
            // Fetch updated league
            guard let newLeague = League(snapshot: snapshot) else {
                print("Error fetching league detail data")
                return
            }
            
            // Update local datasource and table view
            self.league = newLeague
            self.title = newLeague.name
            self.getUsersFromIds(ids: newLeague.memberIds) { newUsers in
                self.users = newUsers
                self.updateTableView()
            }
        }
        
        refObservers.append(refHandle)
    }
    
    // Helper function to fetch user objects from user ids
    func getUsersFromIds(ids: [String], completion: @escaping(_ newUsers: [User]) -> Void) {
        
        var newUsers = [User]()
        
        for id in ids {
            
            // Set user database reference
            let userRef = Database.database().reference(withPath: "users/" + id)
            
            userRef.observeSingleEvent(of: .value, with: { snapshot in
                
                // Fetch user data
                guard let user = User(snapshot: snapshot) else {
                    print("Error fetching user data")
                    return
                }
                
                newUsers.append(user)
                
                guard let lastId = ids.last else {
                    print("No last id in league members list")
                    return
                }
                
                // Call the completion handler when we've added the last user
                if id == lastId {
                    completion(newUsers)
                }
                
            }) { error in
              print(error.localizedDescription)
            }
        }
    }
}

// MARK: - Extensions

// This extention houses table view management functions that utilize the diffable data source API
extension LeagueDetailTableViewController {
    
    // This enum declares table view sections
    enum Section: CaseIterable {
        case one
    }
    
    // Create the the data source and specify what to do with a provided cell
    func createDataSource() -> UITableViewDiffableDataSource<Section, User> {
        
        return UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, user in
            
            // Configure the cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "LeagueDetailCell", for: indexPath) as! LeagueStandingTableViewCell
            cell.configure(with: user)

            return cell
        }
    }
    
    // Apply a snapshot with updated league data
    func updateTableView(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, User>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(users)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}


