//
//  TournamentDetailTableViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/3/23.
//

// MARK: - Imported libraries

import UIKit
import FirebaseAuth
import FirebaseDatabase

// MARK: - Main class

// This class/view controller displays details for the selected tournament
class TournamentDetailTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    @IBOutlet var makePicksButton: UIBarButtonItem!
    @IBOutlet var tournamentActionBarButtonItemGroup: UIBarButtonItemGroup!
    @IBOutlet var lastUpdateTimeLabel: UILabel!
    
    lazy var dataSource = createDataSource()
    var league: League
    var tournament: Tournament
    var standings = [TournamentStanding]()
    let currentFirebaseUser = Auth.auth().currentUser!
    var firstLoad = true
    var updateTimer = Timer()
    
    // Timer update interval in minutes
    let updateInterval = 15.0
    
    // MARK: - Initializers
    
    init?(coder: NSCoder, league: League, tournament: Tournament) {
        self.league = league
        self.tournament = tournament
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View life cycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = dataSource
        
        setupUI()
        
        // Print out athletes and ESPN Ids for import
//        for athlete in tournament.athletes {
//            print(athlete.espnId + "," + athlete.name)
//        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        dismissLoadingIndicator(animated: false)
        
        // Set timer label text depending on tournament status
        if Date.now.timeIntervalSince1970 < tournament.startDate {
            // Tournament hasn't started yet
            lastUpdateTimeLabel.text = "Tournament begins on \(tournament.startDate.formattedDate())"
        } else if Date.now.timeIntervalSince1970 <= tournament.endDate {
            // Tournament is active
            initializeUpdateTimer()
        } else {
            // Tournament has ended
            lastUpdateTimeLabel.text = "Tournament ended on \(tournament.endDate.formattedDate())"
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // If this is the first time displaying this view controller, viewDidLoad will handle updating the table view
        if firstLoad {
            firstLoad = false
        } else {
            //calculateTournamentStandings()
            standings = tournament.calculateStandings(league: league)
            updateTableView()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        updateTimer.invalidate()
    }
    
    // MARK: - Other functions
    
    // Initialize UI elements
    func setupUI() {
        title = tournament.name
        
        setMakePicksButtonState()
        
        // If the current user is not the tournament owner, hide administrative actions
        if tournament.creator != currentFirebaseUser.email {
            tournamentActionBarButtonItemGroup.isHidden = true
            navigationItem.rightBarButtonItem = makePicksButton
        }
        
        // Calculate the standings and update the table view
        //calculateTournamentStandings()
        standings = tournament.calculateStandings(league: league)
        updateTableView()
    }
    
    // Set the state of the Make Picks button
    func setMakePicksButtonState() {
        makePicksButton.isEnabled = false
        
        // Set make picks button text and state
        if tournament.athletes.isEmpty {
            //makePicksButton.title = "Make Picks (Players not yet available)"
        } else if Date.now.timeIntervalSince1970 >= tournament.startDate {
            //makePicksButton.title = "Make Picks (Tournament has started)"
        } else {
            makePicksButton.isEnabled = true
        }
    }
    
    // Set up the update countdown timer
    func initializeUpdateTimer() {
        
        // Create a string formatter to display the time how we want
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        
        var nextUpdateTime = Double()
        var timeLeft: Int {
            Int((nextUpdateTime - Date.now.timeIntervalSince1970).rounded())
        }
        
        // Helper code to set values when update is needed
        let finishUpdateCycle = {
            self.tournament.lastUpdateTime = Date.now.timeIntervalSince1970
            self.tournament.databaseReference.child("lastUpdateTime").setValue(self.tournament.lastUpdateTime)
            nextUpdateTime = Date.now.addingTimeInterval(self.updateInterval*60).timeIntervalSince1970
            
            // Fetch updated tournament data and update UI
            Task {
                var updatedAthleteData = [Athlete]()

                // Attempt to fetch updated athlete data
                do {
                    updatedAthleteData = try await Tournament.fetchEventAthleteData(eventId: self.tournament.espnId)
                } catch EventAthleteDataError.dataTaskError {
                    self.displayAlert(title: "Update Tournament Error", message: "Looks like there was a network issue when fetching updated tournament data. Your connection could be slow, or it may have been interrupted.")
                } catch EventAthleteDataError.invalidHttpResponse {
                    self.displayAlert(title: "Update Tournament Error", message: "Looks like there was an issue when fetching updated tournament data. The server might be temporarily unreachable.")
                } catch EventAthleteDataError.decodingError {
                    self.displayAlert(title: "Update Tournament Error", message: "Looks like there was an issue when decoding the updated tournament data. If you see this message, please reach out to the developer.")
                } catch EventAthleteDataError.noCompetitorData {
                    self.displayAlert(title: "Update Tournament Error", message: "It doesn't look like there is any player data for this tournament right now.")
                } catch {
                    self.displayAlert(title: "Update Tournament Error", message: "Something went wrong, but we're not exactly sure why. If you continue to see this message, reach out to the developer for assistance.")
                }
                
                // Merge the new athlete data with the current data
                self.tournament.athletes = self.tournament.athletes.map({ athlete in
                    
                    // Find the matching athlete
                    guard var updatedAthlete = updatedAthleteData.first(where: { athleteToFind in
                        athleteToFind.espnId == athlete.espnId
                    }) else {
                        print("Couldn't find matching athlete to update")
                        return athlete
                    }
                    
                    // Re-apply the value and odds data
                    updatedAthlete.value = athlete.value
                    updatedAthlete.odds = athlete.odds
                    return updatedAthlete
                })
                
                self.standings = self.tournament.calculateStandings(league: self.league)
                self.updateTableView()

                // Update athlete data in firebase
                try await self.tournament.databaseReference.setValue(self.tournament.toAnyObject())
            }
        }
        
        // Calculate the next update timestamp
        if tournament.lastUpdateTime < Date.now.addingTimeInterval(-updateInterval*60).timeIntervalSince1970 { // 15 minutes ago
            finishUpdateCycle()
        } else {
            nextUpdateTime = tournament.lastUpdateTime + (updateInterval*60) // lastUpdateTime + 15 minutes
        }
        
        // Update countdown with initial value before timer starts
        var formattedTime = formatter.string(from: TimeInterval(timeLeft))!
        self.lastUpdateTimeLabel.text = "Next update in \(formattedTime)"
        
        // Create the timer
        updateTimer = Timer(timeInterval: 1, repeats: true) { _ in
            
            // Check if the countdown has completed
            if timeLeft < 0 {
                finishUpdateCycle()
            }
            
            // Format and present the time remaining until the next update
            formattedTime = formatter.string(from: TimeInterval(timeLeft))!
            self.lastUpdateTimeLabel.text = "Next update in \(formattedTime)"
        }
        
        // Add the timer to the .common runloop so it will update during user interaction
        RunLoop.current.add(updateTimer, forMode: .common)
    }
    
    // Remove tournament data and user associations
    @IBAction func deleteTournamentPressed(_ sender: Any) {
        let deleteTournamentAlert = UIAlertController(title: "Are you sure?", message: "All of the tournament data will be permenantly deleted.", preferredStyle: .alert)
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        let confirm = UIAlertAction(title: "Delete Tournament", style: .destructive) { [unowned deleteTournamentAlert] _ in
            
            // Dismiss the current alert
            deleteTournamentAlert.dismiss(animated: true)
            
            self.displayLoadingIndicator(animated: true)
            self.updateTimer.invalidate()
            
            Task {
                // Remove the tournament data from the tournaments and tournamentIds trees
                try await self.tournament.databaseReference.removeValue()
                try await Database.database().reference().child("tournamentIds").child(self.tournament.id).removeValue()
                
                // Remove the tournament data from the league tournamentIds tree
                try await self.league.databaseReference.child("tournamentIds").child(self.tournament.id).removeValue()
                
                // Return to TournamentsTableViewController
                _ = self.navigationController?.popViewController(animated: true)
            }
        }
        
        deleteTournamentAlert.addAction(cancel)
        deleteTournamentAlert.addAction(confirm)
        
        present(deleteTournamentAlert, animated: true)
    }
    
    // MARK: - Navigation
    
    // Pass tournament data to MakePicksTableViewController
    @IBSegueAction func segueToMakePicks(_ coder: NSCoder) -> MakePicksTableViewController? {
        return MakePicksTableViewController(coder: coder, tournament: tournament)
    }
    
    // Pass tournament data to ManageAthletesTableViewController
    @IBSegueAction func segueToManageAthletes(_ coder: NSCoder) -> ManageAthletesTableViewController? {
        guard let manageAthletesViewController = ManageAthletesTableViewController(coder: coder, tournament: tournament) else { return nil }
        manageAthletesViewController.delegate = self
        return manageAthletesViewController
    }
    
    // Segue to TournamentUserDetailViewController
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Make sure we have picks for the selected user
        guard let tournamentStanding = dataSource.itemIdentifier(for: indexPath),
              let userPicks = tournament.pickIds[tournamentStanding.user.id] else { print("No picks for this user"); return }
        
        var selectedUserPicks = [Athlete]()
        
        // Grab the athlete object for each athlete Id
        for athleteId in userPicks {
            if let athlete = tournament.athletes.first(where: { $0.espnId == athleteId }) {
                selectedUserPicks.append(athlete)
            } else {
                print("Error finding athlete from pick: No matching athlete ID found")
            }
        }
        
        // Sort the picked athletes
        selectedUserPicks = selectedUserPicks.sorted(by: { $0.score < $1.score })
        
        // Verify we can instantiate an instance of TournamentUserDetailTableViewController
        guard let destinationViewController = storyboard?.instantiateViewController(identifier: "TournamentUserDetail", creator: { coder in
            TournamentUserDetailTableViewController(coder: coder, selectedUserEmail: tournamentStanding.user.email, selectedUserPicks: selectedUserPicks)
        }) else { return }
        
        // Push the new view controller
        navigationController?.pushViewController(destinationViewController, animated: true)
    }
    
    // Handle the incoming new picks data
    @IBAction func unwindFromMakePicks(segue: UIStoryboardSegue) {
        
        // Check that we have new picks data to parse
        guard segue.identifier == "makePicksUnwind",
              let sourceViewController = segue.source as? MakePicksTableViewController else { return }
        let pickItems = sourceViewController.pickItems
        
        // Convert pickItems array to Firebase-style dictionary
        var pickDict = [String: Bool]()
        for pick in pickItems {
            if pick.isSelected {
                //pickDict[pick.athlete.id] = true
                pickDict[pick.athlete.espnId] = true
            }
        }
        
        // Save the picks to Firebase
        tournament.databaseReference.child("pickIds").child(currentFirebaseUser.uid).setValue(pickDict)
        
        // Save the picks to the local data source
        let pickArray = pickDict.map { $0.key }
        tournament.pickIds[currentFirebaseUser.uid] = pickArray
        
        // Update the tournament standings and refresh the table view
        //calculateTournamentStandings()
        standings = tournament.calculateStandings(league: league)
        updateTableView()
    }
}

// MARK: - Extensions

// This extention houses table view management functions that utilize the diffable data source API
extension TournamentDetailTableViewController {
    
    // MARK: - Section enum
    
    // This enum declares table view sections
    enum Section: CaseIterable {
        case one
    }
    
    // MARK: - Other functions
    
    // Create the the data source and specify what to do with a provided cell
    func createDataSource() -> UITableViewDiffableDataSource<Section, TournamentStanding> {
        
        return UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, standing in
            
            // Configure the cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "TournamentDetailCell", for: indexPath) as! TournamentStandingTableViewCell
            cell.configure(with: standing)

            return cell
        }
    }
    
    // Apply a snapshot with updated tournament data
    func updateTableView(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, TournamentStanding>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(standings)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}

// This extention conforms to the ManageAthletesDelegate protocol
extension TournamentDetailTableViewController: ManageAthletesDelegate {
    
    // Add a new athlete
    func addAthlete(athlete: Athlete) {
        tournament.athletes.append(athlete)
        setMakePicksButtonState()
    }
    
    // Remove an existing athlete
    func removeAthlete(athlete: Athlete) {
        tournament.athletes.removeAll { $0.id == athlete.id }
        setMakePicksButtonState()
    }
    
    // Update an existing athlete
    func updateAthlete(athlete: Athlete) {
        guard let index = (tournament.athletes.firstIndex { $0.id == athlete.id }) else { return }
        tournament.athletes[index] = athlete
    }
}
