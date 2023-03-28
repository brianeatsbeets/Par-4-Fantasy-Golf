//
//  LeagueDetailTableViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/3/23.
//

// TODO: Figure out best practice for either asynchronously passing league data from league ID or asynchronously initializing LeagueDetailTVC without using an optional and guarding at the beginning of every function
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
    let denormalizedLeague: DenormalizedLeague
    var league: League?
    var standings = [LeagueStanding]()
    
    // MARK: - Initializers
    
    init?(coder: NSCoder, denormalizedLeague: DenormalizedLeague) {
        self.denormalizedLeague = denormalizedLeague
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View life cycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = dataSource
        
        // Initialize the view and data
        Task {
            await fetchInitialLeagueData()
        }
    }
    
    // MARK: - Other functions
    
    // Fetch the initial league data and update the UI
    // TODO: Find a better function name and/or combine with fetchUpdatedLeagueData
    func fetchInitialLeagueData() async {
        
        // Create league object from league id
        guard var league = await League.fetchSingleLeague(from: denormalizedLeague.id) else {
            print("Failed to fetch league from denormalized league id")
            return
        }
        
        title = league.name
        
        // If the current user is not the league owner, hide administrative actions
        if league.creator != Auth.auth().currentUser!.email {
            leagueActionBarButtonItemGroup.isHidden = true
            navigationItem.rightBarButtonItem = makePicksButton
        }
        
        // Populate league members and standings
        Task {
            league.members = await User.fetchMultipleUsers(from: league.memberIds)
            self.league = league
            await calculateLeagueStandings()
            updateTableView()
        }
    }
    
    // Fetch the most recent league data
    // TODO: Use observeSingleEvent instead?
    func fetchUpdatedLeagueData() async {
        
        guard var league = self.league else { return }
        
        do {
            let snapshot = try await league.databaseReference.getData()
            if let newLeague = League(snapshot: snapshot) {
                league = newLeague
                league.members = await User.fetchMultipleUsers(from: league.memberIds)
                self.league = league
                await self.calculateLeagueStandings()
            } else {
                print("Error creating league")
            }
        } catch {
            print("Error caught")
        }
    }
    
    // Calculate the league standings
    // TODO: Figure out if it would be more efficient to have league.picks be [User: [Athlete]] vs. [String: [String]] (probably would be)
    func calculateLeagueStandings() async {
        
        guard let league = self.league else { return }
        
        var newStandings = [LeagueStanding]()
        
        for user in league.members {
            guard let userPicks = league.picks[user.id] else { continue }
            
            let athletes = await Athlete.fetchMultipleAthletes(from: userPicks, leagueId: league.id)
            
            var topAthletes = [Athlete]()
            
            if !athletes.isEmpty {
                let sortedAthletes = athletes.sorted(by: <)
                let athleteCount = sortedAthletes.count >= 4 ? 3 : sortedAthletes.count - 1
                topAthletes = Array(sortedAthletes[0...athleteCount])
            }
            
            let userStanding = LeagueStanding(leagueId: league.id, user: user, topAthletes: topAthletes)
            newStandings.append(userStanding)
        }
        
        standings = newStandings.sorted(by: <)
    }
    
    // Remove league data and user associations
    @IBAction func deleteLeaguePressed(_ sender: Any) {
        
        guard let league = self.league else { return }
        
        let deleteLeagueAlert = UIAlertController(title: "Are you sure?", message: "All of the league data will be permenantly deleted.", preferredStyle: .alert)
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        let confirm = UIAlertAction(title: "Yes", style: .destructive) { [unowned deleteLeagueAlert] _ in
            
            // Dismiss the current alert
            deleteLeagueAlert.dismiss(animated: true)
            
            // Remove the league from each user's leagues
            for user in league.members {
                user.databaseReference.child("leagues").child(league.id).removeValue()
            }
            
            // Remove the league data from the leagues and leagueIds trees
            league.databaseReference.removeValue()
            Database.database().reference(withPath: "leagueIds").child(league.id).removeValue()
            
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
        guard let league = self.league else { return nil }
        return ManageUsersTableViewController(coder: coder, league: league)
    }
    
    // Pass league data to MakePicksTableViewController
    @IBSegueAction func segueToMakePicks(_ coder: NSCoder) -> MakePicksTableViewController? {
        guard let league = self.league else { return nil }
        return MakePicksTableViewController(coder: coder, league: league)
    }
    
    // Pass league data to ManageAthletesTableViewController
    @IBSegueAction func segueToManageAthletes(_ coder: NSCoder) -> ManageAthletesTableViewController? {
        guard let league = self.league else { return nil }
        return ManageAthletesTableViewController(coder: coder, league: league)
    }
    
    // Handle the incoming new picks data
    @IBAction func unwindFromMakePicks(segue: UIStoryboardSegue) {
        
        guard let league = self.league else { return }
        
        // Check that we have new picks data to parse
        guard segue.identifier == "makePicksUnwind",
              let sourceViewController = segue.source as? MakePicksTableViewController else { return }
        
        let pickItems = sourceViewController.pickItems
        let userPicksRef = league.databaseReference.child("picks").child(Auth.auth().currentUser!.uid)
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
            updateTableView()
        }
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


