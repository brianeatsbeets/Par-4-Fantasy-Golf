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
        
        title = league.name
        
        // If the current user is not the league owner, hide administrative actions
        if league.creator != Auth.auth().currentUser!.email {
            leagueActionBarButtonItemGroup.isHidden = true
            navigationItem.rightBarButtonItem = makePicksButton
        }
        
        tableView.dataSource = dataSource
        
        // Populate league members and standings
        Task {
            league.members = await User.fetchMultipleUsers(from: self.league.memberIds)
            await calculateLeagueStandings()
            updateTableView()
        }
    }
    
    // MARK: - Other functions
    
    // Fetch the most recent league data
    // TODO: Use observeSingleEvent instead?
    func fetchUpdatedLeagueData() async {
        do {
            let snapshot = try await league.databaseReference.getData()
            if let newLeague = League(snapshot: snapshot) {
                league = newLeague
                league.members = await User.fetchMultipleUsers(from: self.league.memberIds)
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
        print("Calculating league standings for \(league.members.count) members...")
        
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
        return ManageAthletesTableViewController(coder: coder, league: league)
    }
    
    // Handle the incoming new picks data
    @IBAction func unwindFromMakePicks(segue: UIStoryboardSegue) {
        
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


