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
import Combine

// MARK: - Main class

// This class/view controller displays details for the selected tournament
class TournamentDetailTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    @IBOutlet var makePicksButton: UIBarButtonItem!
    @IBOutlet var tournamentActionBarButtonItemGroup: UIBarButtonItemGroup!
    @IBOutlet var lastUpdateTimeLabel: UILabel!
    
    lazy var dataSource = createDataSource()
    
    var dataStore: DataStore
    let leagueIndex: Int
    let tournamentIndex: Int
    var league: League
    var tournament: Tournament
    var subscription: AnyCancellable?
    
    let currentFirebaseUser = Auth.auth().currentUser!
    var firstLoad = true
    var updateTimer = Timer()
    
    // Timer update interval in seconds
    let updateInterval: Double = 1*60
    
    // MARK: - Initializers
    
    init?(coder: NSCoder, dataStore: DataStore, leagueIndex: Int, tournamentIndex: Int) {
        self.dataStore = dataStore
        self.leagueIndex = leagueIndex
        self.tournamentIndex = tournamentIndex
        league = dataStore.leagues[leagueIndex]
        tournament = league.tournaments[tournamentIndex]
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View life cycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = dataSource
        subscribeToDataStore()
        setupUI()
        
        // Print out athletes and ESPN Ids for import
//        for athlete in tournament.athletes {
//            print(athlete.espnId + "," + athlete.name)
//        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // If this is the first time displaying this view controller, viewDidLoad will handle updating the table view
        if firstLoad {
            firstLoad = false
        } else {
            updateTableView()
        }
    }
    
    // MARK: - Other functions
    
    // Create a subscription for the datastore
    func subscribeToDataStore() {
        subscription = dataStore.$leagues.sink(receiveCompletion: { _ in
            print("Completion")
        }, receiveValue: { [weak self] leagues in
            print("TournamentDetailTableVC received updated value for leagues")
            
            // If this view controller has been dismissed, skip assigning self-referencing values below
            guard let self else { return }
            
            // Update VC local league variable
            self.league = leagues[self.leagueIndex]
            self.tournament = leagues[self.leagueIndex].tournaments[self.tournamentIndex]
            
            // Initialize the timer if the tournament is live
            if self.tournament.status == .live {
                self.initializeUpdateTimer()
            } else {
                self.lastUpdateTimeLabel.text = "Tournament ended on \(self.tournament.endDate.formattedDate())"
            }
            
            // TODO: Ony update table view when view is visible
            self.updateTableView()
        })
    }
    
    // Initialize UI elements
    func setupUI() {
        title = tournament.name
        
        setMakePicksButtonState()
        
        setTournamentStatusText()
        
        // If the current user is not the tournament owner, hide administrative actions
        if tournament.creator != currentFirebaseUser.email {
            tournamentActionBarButtonItemGroup.isHidden = true
            navigationItem.rightBarButtonItem = makePicksButton
        }
        
        // Calculate the standings and update the table view
        updateTableView()
    }
    
    // Set timer label text depending on tournament status
    func setTournamentStatusText() {
        switch tournament.status {
        case .scheduled:
            lastUpdateTimeLabel.text = "Tournament begins on \(tournament.startDate.formattedDate())"
        case .completed:
            lastUpdateTimeLabel.text = "Tournament ended on \(tournament.endDate.formattedDate())"
        case .live:
            break
        }
    }
    
    // Set the state of the Make Picks button
    // TODO: Fix button text being too long when user is not league owner
    func setMakePicksButtonState() {
        makePicksButton.isEnabled = true //false
        
        guard !tournament.athletes.isEmpty else {
            makePicksButton.title = "Make Picks (Players data not yet available)"
            return
        }
        
        switch tournament.status {
        case .scheduled:
            makePicksButton.isEnabled = true
        case .live:
            makePicksButton.title = "Make Picks (Tournament has started)"
        case .completed:
            makePicksButton.title = "Make Picks (Tournament has completed)"
        }
    }
    
    // Fetch the updated score data
    func fetchScoreData() async throws {
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
        
        var nonMatchingAthletes = [Athlete]()
        
        // Merge the new athlete data with the current data
        self.dataStore.leagues[leagueIndex].tournaments[tournamentIndex].athletes = self.tournament.athletes.map({ athlete in
            
            // Find the matching athlete
            guard var updatedAthlete = updatedAthleteData.first(where: { athleteToFind in
                athleteToFind.espnId == athlete.espnId
            }) else {
                print("Couldn't find new data for \(athlete.name) (ID \(athlete.espnId))")
                nonMatchingAthletes.append(athlete)
                return athlete
            }
            
            // Re-apply the value and odds data
            updatedAthlete.value = athlete.value
            updatedAthlete.odds = athlete.odds
            return updatedAthlete
        })
        
        // If there are non-matching athletes, display an alert containing them to the league owner
        if !nonMatchingAthletes.isEmpty && self.tournament.creator == self.currentFirebaseUser.email {
            let nonMatchingAthletesString = nonMatchingAthletes.map{ "\($0.name) (ESPN ID: \($0.espnId))" }.joined(separator: "\n")
            self.displayAlert(title: "Mismatched Athlete IDs", message: "One or more athletes have incorrect ESPN IDs, so score data for those athletes could not be updated. Please correct their ESPN IDs in the Manage Athletes view.\n\nAffected athletes:\n\(nonMatchingAthletesString)")
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
        
        // Calculate the next update timestamp
        if tournament.lastUpdateTime < Date.now.addingTimeInterval(-updateInterval).timeIntervalSince1970 { // 15 minutes ago
            nextUpdateTime = Date.now.addingTimeInterval(self.updateInterval).timeIntervalSince1970
        } else {
            nextUpdateTime = tournament.lastUpdateTime + (updateInterval) // lastUpdateTime + 15 minutes
        }
        
        // Update countdown with initial value before timer starts
        var formattedTime = formatter.string(from: TimeInterval(timeLeft))!
        self.lastUpdateTimeLabel.text = "Next update in \(formattedTime)"
        
        // Create the timer
        updateTimer = Timer(timeInterval: 1, repeats: true) { timer in
            
            // Check if the countdown has completed
            if timeLeft < 1 {
                
                timer.invalidate()
                
                if self.tournament.status == .completed {
                    self.lastUpdateTimeLabel.text = "Fetching final results..."
                } else {
                    self.lastUpdateTimeLabel.text = "Updating..."
                }
            } else {
                
                // Format and present the time remaining until the next update
                formattedTime = formatter.string(from: TimeInterval(timeLeft))!
                self.lastUpdateTimeLabel.text = "Next update in \(formattedTime)"
            }
        }
        
        // Add the timer to the .common runloop so it will update during user interaction
        RunLoop.current.add(updateTimer, forMode: .common)
    }
    
    // Remove tournament data and user associations
    @IBAction func deleteTournamentPressed(_ sender: Any) {
        let deleteTournamentAlert = UIAlertController(title: "Are you sure?", message: "All of the tournament data will be permenantly deleted.", preferredStyle: .alert)
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        let confirm = UIAlertAction(title: "Delete Tournament", style: .destructive) { _ in
            
            self.updateTimer.invalidate()
            
            // Cancel the subscription early to prevent updating the local league variable with league data that no longer exists
            self.subscription?.cancel()
            
            // Return to LeagueDetailTableViewController
            self.performSegue(withIdentifier: "unwindDeleteTournament", sender: nil)
        }
        
        deleteTournamentAlert.addAction(cancel)
        deleteTournamentAlert.addAction(confirm)
        
        present(deleteTournamentAlert, animated: true)
    }
    
    // Disable highlighting standing cells with no picked users
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        guard let standing = dataSource.itemIdentifier(for: indexPath),
              !standing.topAthletes.isEmpty else { return false}
        
        return true
    }
    
    // MARK: - Navigation
    
    // Pass tournament data to MakePicksTableViewController
    @IBSegueAction func segueToMakePicks(_ coder: NSCoder) -> MakePicksTableViewController? {
        return MakePicksTableViewController(coder: coder, tournament: tournament)
    }
    
    // Pass tournament data to ManageAthletesTableViewController
    @IBSegueAction func segueToManageAthletes(_ coder: NSCoder) -> ManageAthletesTableViewController? {
        return ManageAthletesTableViewController(coder: coder, dataStore: dataStore, leagueIndex: leagueIndex, tournamentIndex: tournamentIndex)
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
    
    // Disable selection/segue for user standings that have no picks
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let standing = dataSource.itemIdentifier(for: indexPath),
              !standing.topAthletes.isEmpty else { return nil}
        
        return indexPath
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
                pickDict[pick.athlete.espnId] = true
            }
        }
        
        // Save the picks to Firebase
        tournament.databaseReference.child("pickIds").child(currentFirebaseUser.uid).setValue(pickDict)
        
        // Temp tournament to avoid writing to the data store multiple times
        var tempTournament = dataStore.leagues[leagueIndex].tournaments[tournamentIndex]
        
        // Save the picks to the local data source
        let pickArray = pickDict.map { $0.key }
        tempTournament.pickIds[currentFirebaseUser.uid] = pickArray
        
        // Update the tournament standings and refresh the table view
        tempTournament.standings = tempTournament.calculateStandings(leagueMembers: league.members)
        
        dataStore.leagues[leagueIndex].tournaments[tournamentIndex] = tempTournament
        
        // TODO: Throwing warning (I think this only happens when it is animated) - UITableView was told to layout its visible cells and other contents without being in the view hierarchy
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
            cell.configure(with: standing, tournamentStarted: self.tournament.status != .scheduled)

            return cell
        }
    }
    
    // Apply a snapshot with updated tournament data
    func updateTableView(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, TournamentStanding>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(tournament.standings)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}
