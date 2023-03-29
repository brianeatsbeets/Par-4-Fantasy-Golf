//
//  LeagueDetailTableViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/3/23.
//

// TODO: Have Make Picks button show an alert when no athletes exist and prevent segue
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
        if league.creator != Auth.auth().currentUser!.email {
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
        
        print("viewDidAppear")
        print("Athlete count: \(league.athletes.count)")
        
        // If this is the first time displaying this view controller, viewDidLoad will handle updating the table view
        if firstLoad {
            firstLoad = false
        } else {
            calculateLeagueStandings()
            updateTableView()
        }
    }
    
    // MARK: - Other functions
    
    // Fetch the most recent league data
    // TODO: Use observeSingleEvent instead?
    func fetchUpdatedLeagueData() async {
        
        print("Fetching updated league data")
        
        do {
            let snapshot = try await league.databaseReference.getData()
            if let newLeague = League(snapshot: snapshot) {
                league = newLeague
                league.members = await User.fetchMultipleUsers(from: self.league.memberIds)
                self.calculateLeagueStandings()
            } else {
                print("Error creating league")
            }
        } catch {
            print("Error caught")
        }
    }
    
    // Calculate the league standings
    // TODO: Sort by name if tournament hasn't started yet
    func calculateLeagueStandings() {
        print("Calculating league standings")
        
        var newStandings = [LeagueStanding]()
        
        // Create a league standing object for each user
        for user in league.members {
            
            // Make sure the user has picked at least one athlete
            guard let userPicks = league.pickIds[user.id] else { continue }
            
            // Fetch the picked athletes
            let athletes = league.athletes.filter { userPicks.contains([$0.id]) }
            
            var topAthletes = [Athlete]()
            
            // Sort and copy the top athletes to a new array
            if !athletes.isEmpty {
                let sortedAthletes = athletes.sorted { $0.score < $1.score }
                let athleteCount = sortedAthletes.count >= 4 ? 3 : sortedAthletes.count - 1
                topAthletes = Array(sortedAthletes[0...athleteCount])
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
        return ManageUsersTableViewController(coder: coder, league: league)
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
        let userPicksRef = league.databaseReference.child("pickIds").child(Auth.auth().currentUser!.uid)
        var pickDict = [String: Bool]()
        
        // Convert pickItems array to Firebase-style dictionary
        for pick in pickItems {
            if pick.isSelected {
                pickDict[pick.athlete.id] = true
            }
        }
        
        // Save the picks to Firebase
        userPicksRef.setValue(pickDict)
        
        // Fetch the most recent league data and refresh the table view
        Task {
            await fetchUpdatedLeagueData()
            //await calculateLeagueStandings()
            updateTableView()
        }
    }
}

// MARK: - Extensions

// This extention conforms to the ManageAthletesDelegate protocol
extension LeagueDetailTableViewController: ManageAthletesDelegate {
    
    // Add a new athlete
    func addAthlete(athlete: Athlete) {
        league.athletes.append(athlete)
        print("Added athlete: \(athlete)")
    }
    
    // Remove an existing athlete
    func removeAthlete(athlete: Athlete) {
        league.athletes.removeAll { $0.id == athlete.id }
        print("Removed athlete: \(athlete)")
    }
    
    // Update an existing athlete
    func updateAthlete(athlete: Athlete) {
        guard let index = (league.athletes.firstIndex { $0.id == athlete.id }) else { return }
        league.athletes[index] = athlete
        print("Updated athlete: \(athlete)")
    }
}

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
            cell.configure(with: standing)

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

