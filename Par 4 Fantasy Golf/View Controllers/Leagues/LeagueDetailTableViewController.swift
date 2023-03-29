//
//  LeagueDetailTableViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/3/23.
//

// TODO: Have Make Picks button show an alert when no athletes exist and prevent segue
// TODO: If we are on or after the league start date, disable or add an alert to Make Picks button and prevent segue
// TODO: Prevent all rows from reloading when saving updated picks

// MARK: - Imported libraries

import UIKit
import FirebaseAuth
import FirebaseDatabase

// MARK: - Main class

// This class/view controller displays details for the selected league
class LeagueDetailTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    @IBOutlet var makePicksButton: UIBarButtonItem!
    @IBOutlet var leagueActionBarButtonItemGroup: UIBarButtonItemGroup!
    
    lazy var dataSource = createDataSource()
    var league: League
    var standings = [LeagueStanding]()
    let currentFirebaseUser = Auth.auth().currentUser!
    var firstLoad = true
    
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
            leagueActionBarButtonItemGroup.isHidden = true
            navigationItem.rightBarButtonItem = makePicksButton
        }
        
        Task {
            league.members = await User.fetchMultipleUsers(from: self.league.memberIds)
            calculateLeagueStandings()
            updateTableView()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // If this is the first time displaying this view controller, viewDidLoad will handle updating the table view
        if firstLoad {
            firstLoad = false
        } else {
            calculateLeagueStandings()
            updateTableView()
        }
    }
    
    // MARK: - Other functions
    
    // Calculate the league standings
    // TODO: Sort by name if tournament hasn't started yet
    func calculateLeagueStandings() {
        print("Calculating league standings")
        
        var newStandings = [LeagueStanding]()
        
        // Create a league standing object for each user
        for user in league.members {
            
            var topAthletes = [Athlete]()
            
            // If user has picked at least one athlete, calculate the top athletes
            if let userPicks = league.pickIds[user.id] {
                
                // Fetch the picked athletes
                let athletes = league.athletes.filter { userPicks.contains([$0.id]) }
                
                // Sort and copy the top athletes to a new array
                if !athletes.isEmpty {
                    let sortedAthletes = athletes.sorted { $0.score < $1.score }
                    let athleteCount = sortedAthletes.count >= 4 ? 3 : sortedAthletes.count - 1
                    topAthletes = Array(sortedAthletes[0...athleteCount])
                }
            }
            
            // Create and append a new league standing to the temporary container
            let userStanding = LeagueStanding(leagueId: league.id, user: user, topAthletes: topAthletes)
            newStandings.append(userStanding)
        }
        
        // Save the new league standings
        standings = newStandings.sorted(by: <)
    }
    
    // Remove league data and user associations
    @IBAction func deleteLeaguePressed(_ sender: Any) {
        let deleteLeagueAlert = UIAlertController(title: "Are you sure?", message: "All of the league data will be permenantly deleted.", preferredStyle: .alert)
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        let confirm = UIAlertAction(title: "Yes", style: .destructive) { [unowned deleteLeagueAlert] _ in
            
            // Dismiss the current alert
            deleteLeagueAlert.dismiss(animated: true)
            
            // Remove the league from each user's leagues
            for user in self.league.members {
                user.databaseReference.child("leagues").child(self.league.id).removeValue()
            }
            
            // Remove the league data
            self.league.databaseReference.removeValue()
            
            // Return to LeaguesTableViewController
            self.navigationController?.popViewController(animated: true)
        }
        
        deleteLeagueAlert.addAction(cancel)
        deleteLeagueAlert.addAction(confirm)
        
        present(deleteLeagueAlert, animated: true)
    }
    
    // MARK: - Navigation
    
    // Pass league data to ManageUsersTableViewController
    @IBSegueAction func segueToManageUsers(_ coder: NSCoder) -> ManageUsersTableViewController? {
        guard let manageUsersViewController = ManageUsersTableViewController(coder: coder, league: league) else { return nil }
        manageUsersViewController.delegate = self
        return manageUsersViewController
    }
    
    // Pass league data to MakePicksTableViewController
    @IBSegueAction func segueToMakePicks(_ coder: NSCoder) -> MakePicksTableViewController? {
        return MakePicksTableViewController(coder: coder, league: league)
    }
    
    // Pass league data to ManageAthletesTableViewController
    @IBSegueAction func segueToManageAthletes(_ coder: NSCoder) -> ManageAthletesTableViewController? {
        guard let manageAthletesViewController = ManageAthletesTableViewController(coder: coder, league: league) else { return nil }
        manageAthletesViewController.delegate = self
        return manageAthletesViewController
    }
    
    // Handle the incoming new picks data
    // TODO: Optimize to only write/delete necessary pick data
    @IBAction func unwindFromMakePicks(segue: UIStoryboardSegue) {
        
        // Check that we have new picks data to parse
        guard segue.identifier == "makePicksUnwind",
              let sourceViewController = segue.source as? MakePicksTableViewController else { return }
        let pickItems = sourceViewController.pickItems
        
        // Convert pickItems array to Firebase-style dictionary
        var pickDict = [String: Bool]()
        for pick in pickItems {
            if pick.isSelected {
                pickDict[pick.athlete.id] = true
            }
        }
        
        // Save the picks to Firebase
        league.databaseReference.child("pickIds").child(currentFirebaseUser.uid).setValue(pickDict)
        
        // Save the picks to the local data source
        let pickArray = pickDict.map { $0.key }
        league.pickIds[currentFirebaseUser.uid] = pickArray
        
        // Update the league standings and refresh the table view
        calculateLeagueStandings()
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
    func createDataSource() -> UITableViewDiffableDataSource<Section, LeagueStanding> {
        
        return UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, standing in
            
            // Configure the cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "LeagueDetailCell", for: indexPath) as! LeagueStandingTableViewCell
            cell.configure(with: standing, at: indexPath.row)

            return cell
        }
    }
    
    // Apply a snapshot with updated league data
    func updateTableView(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, LeagueStanding>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(standings)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}

// This extention conforms to the ManageAthletesDelegate protocol
extension LeagueDetailTableViewController: ManageAthletesDelegate {
    
    // Add a new athlete
    func addAthlete(athlete: Athlete) {
        league.athletes.append(athlete)
    }
    
    // Remove an existing athlete
    func removeAthlete(athlete: Athlete) {
        league.athletes.removeAll { $0.id == athlete.id }
    }
    
    // Update an existing athlete
    func updateAthlete(athlete: Athlete) {
        guard let index = (league.athletes.firstIndex { $0.id == athlete.id }) else { return }
        league.athletes[index] = athlete
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
