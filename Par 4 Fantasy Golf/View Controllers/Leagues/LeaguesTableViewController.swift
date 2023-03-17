//
//  LeaguesTableViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/1/23.
//

// TODO: Figure out why league sometimes updates after returning from league details (maybe related to sorting?)

// MARK: - Imported libraries

import UIKit
import FirebaseDatabase

// MARK: - Main class

// This class/view controller displays available leagues
class LeaguesTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    lazy var dataSource = createDataSource()
    var leagues = [League]()
    
    let leaguesRef = Database.database().reference(withPath: "leagues")
    var refObservers: [DatabaseHandle] = []
    
    // MARK: - View life cycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = dataSource
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        createLeaguesDataObserver()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Remove all observers
        refObservers.forEach(leaguesRef.removeObserver(withHandle:))
        refObservers = []
    }
    
    // MARK: - Other functions
    
    // Create the reference observer for league data
    func createLeaguesDataObserver() {
        
        // Observe league data
        let refHandle = leaguesRef.observe(.value) { snapshot in
            
            var newLeagues = [League]()
            
            // Fetch updated leagues
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let league = League(snapshot: snapshot) {
                    newLeagues.append(league)
                }
            }
            
            // Update local datasource and table view
            self.leagues = newLeagues
            self.updateTableView()
        }
        
        refObservers.append(refHandle)
    }
    
    // Handle the incoming new league data
    @IBAction func unwindFromCreateLeague(segue: UIStoryboardSegue) {
        
        // Check that we have new league data to parse
        guard segue.identifier == "createLeagueUnwind",
              let sourceViewController = segue.source as? CreateLeagueTableViewController,
              let league = sourceViewController.league
        else { return }
        
        // Save the league to Firebase
        let leagueRef = leaguesRef.child(league.id.uuidString)
        leagueRef.setValue(league.toAnyObject())
    }
    
    // Prepare league data to send to LeagueDetailViewController
    @IBSegueAction func segueToLeagueDetails(_ coder: NSCoder, sender: Any?) -> LeagueDetailTableViewController? {
        
        // Check to see if a cell was tapped
        guard let cell = sender as? UITableViewCell,
              let indexPath = tableView.indexPath(for: cell),
              let league = dataSource.itemIdentifier(for: indexPath)
        else {
            return nil
        }
        
        // If so, pass the tapped post to view/edit
        return LeagueDetailTableViewController(coder: coder, league: league)
    }
    
    
}

// MARK: - Extensions

// This extention houses table view management functions that utilize the diffable data source API
extension LeaguesTableViewController {
    
    // This enum declares table view sections
    enum Section: CaseIterable {
        case one
    }
    
    // Create the the data source and specify what to do with a provided cell
    func createDataSource() -> UITableViewDiffableDataSource<Section, League> {
        
        return UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, league in
            
            // Configure the cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "LeagueCell", for: indexPath) as! LeagueTableViewCell
            cell.configure(with: league)

            return cell
        }
    }
    
    // Apply a snapshot with updated league data
    func updateTableView(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, League>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(leagues)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}
