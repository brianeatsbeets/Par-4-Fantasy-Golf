//
//  ManageAthletesTableViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/23/23.
//

// MARK: - Imported libraries

import UIKit
import FirebaseAuth
import FirebaseDatabase

// MARK: - Protocols

// This protocol allows conformers to be notified of updates to the athletes managed by this view controller
protocol ManageAthletesDelegate: AnyObject {
    func addAthlete(athlete: Athlete)
    func removeAthlete(athlete: Athlete)
    func updateAthlete(athlete: Athlete)
}

// MARK: - Main class

// This class/view controller allows the user to manage athletes for a given tournament
class ManageAthletesTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    lazy var dataSource = createDataSource()
    var tournament: Tournament
    weak var delegate: ManageAthletesDelegate?
    let userPicksRef: DatabaseReference
    
    // MARK: - Initializers
    
    init?(coder: NSCoder, tournament: Tournament) {
        self.tournament = tournament
        self.userPicksRef = tournament.databaseReference.child("pickIds").child(Auth.auth().currentUser!.uid)
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
    
    // Update the data source when a cell is tapped
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Navigation
    
    // Pass tournament data to ManageAthletesTableViewController
    @IBSegueAction func segueToAddEditAthlete(_ coder: NSCoder, sender: Any?) -> AddEditAthleteTableViewController? {
        
        // Check if we're creating a new athlete or editing an existing one
        if let athleteCell = sender as? UITableViewCell,
           let indexPath = tableView.indexPath(for: athleteCell),
           let athlete = dataSource.itemIdentifier(for: indexPath) {
            return AddEditAthleteTableViewController(coder: coder, athlete: athlete, athleteRefPath: "tournaments/\(tournament.id)/athletes/\(athlete.id)")
        } else {
            return AddEditAthleteTableViewController(coder: coder, athlete: nil, athleteRefPath: nil)
        }
    }
    
    // Handle the incoming athlete data
    @IBAction func unwindFromAddEditAthlete(segue: UIStoryboardSegue) {
        
        // Check that we have new athlete data to parse
        guard segue.identifier == "unwindSaveAthlete",
              let sourceViewController = segue.source as? AddEditAthleteTableViewController,
              let newAthlete = sourceViewController.athlete else { return }
        
        let tournamentAthletesRef = tournament.databaseReference.child("athletes").child(newAthlete.id)
        
        // If we have an athlete with a matching ID, replace it; otherwise, append it
        if let athleteIndex = tournament.athletes.firstIndex(where: { $0.id == newAthlete.id }) {
            tournament.athletes[athleteIndex] = newAthlete
            delegate?.updateAthlete(athlete: newAthlete)
        } else {
            tournament.athletes.append(newAthlete)
            delegate?.addAthlete(athlete: newAthlete)
        }
        
        tournament.athletes = tournament.athletes.sorted(by: { $0.name < $1.name })
        
        // Save the athlete to Firebase
        tournamentAthletesRef.setValue(newAthlete.toAnyObject())
        
        // Update the table view
        updateTableView()
    }
}

// MARK: - Extensions

// This extention houses table view management functions that utilize the diffable data source API
extension ManageAthletesTableViewController {
    
    // MARK: - Diffable data source subclass
    
    // Subclass of UITableViewDiffableDataSource that supports swipe-to-delete
    class SwipeToDeleteDataSource: UITableViewDiffableDataSource<Section, Athlete> {
        
        // MARK: - Properties
        
        var tournamentAthletesRef = DatabaseReference()
        var tournamentPicksRef = DatabaseReference()
        var selectedTournament: Tournament!
        weak var delegate: ManageAthletesDelegate?
        
        // MARK: - Other functions
        
        // Enable swipe-to-delete
        override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            return true
        }
        
        // Determine behavior when a row is deleted
        override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            guard let athlete = itemIdentifier(for: indexPath),
                  editingStyle == .delete else { return }
            
            // Remove the athlete from the tournament's athletes, both in the local data source and in firebase
            if let index = selectedTournament.athletes.firstIndex(where: { $0.id == athlete.id }) {
                selectedTournament.athletes.remove(at: index)
                delegate?.removeAthlete(athlete: athlete)
            }
            tournamentAthletesRef.child(athlete.id).removeValue()
            
            // Remove the athlete pick from each user's picks in this tournament, both in the local data source and in firebase
            for userPicks in selectedTournament.pickIds {
                if let index = userPicks.value.firstIndex(of: athlete.id) {
                    selectedTournament.pickIds[userPicks.key]?.remove(at: index)
                    tournamentPicksRef.child(userPicks.key).child(athlete.id).removeValue()
                }
            }
            
            // Update the data source
            var snapshot = NSDiffableDataSourceSnapshot<Section, Athlete>()
            snapshot.appendSections(Section.allCases)
            snapshot.appendItems(selectedTournament.athletes)
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
        
        let dataSource = SwipeToDeleteDataSource(tableView: tableView) { tableView, indexPath, athlete in
            
            // Configure the cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "AthleteCell", for: indexPath)
            
            var config = cell.defaultContentConfiguration()
            config.text = athlete.name
            config.secondaryText = "Value: \(athlete.value) | Odds: \(athlete.odds) | Score: \(athlete.score)"
            cell.contentConfiguration = config

            return cell
        }
        
        // Variables that allow the custom data source to access the current tournament's firebase database reference to delete data
        dataSource.tournamentAthletesRef = tournament.databaseReference.child("athletes")
        dataSource.tournamentPicksRef = tournament.databaseReference.child("pickIds")
        dataSource.selectedTournament = tournament
        dataSource.delegate = delegate
        
        return dataSource
    }
    
    // Apply a snapshot with updated athlete data
    func updateTableView(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Athlete>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(tournament.athletes)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}
