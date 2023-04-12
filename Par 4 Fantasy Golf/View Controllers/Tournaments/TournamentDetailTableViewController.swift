//
//  TournamentDetailTableViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/3/23.
//

// TODO: Have Make Picks button show an alert when no athletes exist and prevent segue
// TODO: Tap on a user to see their picked athletes and their stats

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
        
        title = tournament.name
        
        // Enable/disable make picks button based on tournament status
        //tournamentStartedSwitch.isOn = tournament.tournamentHasStarted
        //if tournamentStartedSwitch.isOn {
            //makePicksButton.isEnabled = false
        //}
        
        // If the current user is not the tournament owner, hide administrative actions
        if tournament.creator != currentFirebaseUser.email {
            tournamentActionBarButtonItemGroup.isHidden = true
            navigationItem.rightBarButtonItem = makePicksButton
        }
        
        Task {
            calculateTournamentStandings()
            updateTableView()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Check if the tournament has started
        if Date.now.timeIntervalSince1970 >= tournament.startDate {
            // If so, initialize update timer
            initializeUpdateTimer()
        } else {
            // If not, display tournament start date
            lastUpdateTimeLabel.text = "Tournament begins on \(tournament.startDate.formattedDate())"
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // If this is the first time displaying this view controller, viewDidLoad will handle updating the table view
        if firstLoad {
            firstLoad = false
        } else {
            calculateTournamentStandings()
            updateTableView()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        updateTimer.invalidate()
    }
    
    // MARK: - Other functions
    
    // Set up the update countdown timer
    func initializeUpdateTimer() {
        
        // Create a string formatter to display the time how we want
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        
        var nextUpdateTime = Double()
        
        // Helper code to set values when update is needed
        let finishUpdateCycle = {
            self.tournament.lastUpdateTime = Date.now.timeIntervalSince1970
            self.tournament.databaseReference.child("lastUpdateTime").setValue(self.tournament.lastUpdateTime)
            nextUpdateTime = Date.now.addingTimeInterval(self.updateInterval*60).timeIntervalSince1970
        }
        
        // Calculate the next update timestamp
        if tournament.lastUpdateTime < Date.now.addingTimeInterval(-updateInterval*60).timeIntervalSince1970 { // 15 minutes ago
            finishUpdateCycle()
        } else {
            nextUpdateTime = tournament.lastUpdateTime + (updateInterval*60) // lastUpdateTime + 15 minutes
        }
        
        // Update countdown with initial value before timer starts
        var timeLeft = Int((nextUpdateTime - Date.now.timeIntervalSince1970).rounded())
        var formattedTime = formatter.string(from: TimeInterval(timeLeft))!
        self.lastUpdateTimeLabel.text = "Next update in \(formattedTime)"
        
        // Create the timer
        updateTimer = Timer(timeInterval: 1, repeats: true) { _ in
            
            // Calculate the amount of time left until the next update
            timeLeft = Int((nextUpdateTime - Date.now.timeIntervalSince1970).rounded())
            
            // Check if the countdown has completed
            if timeLeft < 0 {
                finishUpdateCycle()
                timeLeft = Int((nextUpdateTime - Date.now.timeIntervalSince1970).rounded())
                
                // Fetch updated tournament data and update UI
                Task {
                    
                    // Attempt to fetch updated athlete info
                    self.tournament.athletes = await Tournament.fetchEventAthletes(eventId: self.tournament.espnId)
                    self.calculateTournamentStandings()
                    self.updateTableView()
                    
                    // Update athlete data in forebase
                    try await self.tournament.databaseReference.setValue(self.tournament.toAnyObject())
                }
            }
            
            // Format the time left
            formattedTime = formatter.string(from: TimeInterval(timeLeft))!
            
            // Update the label text
            self.lastUpdateTimeLabel.text = "Next update in \(formattedTime)"
        }
        
        // Add the timer to the .common runloop so it will update during user interaction
        RunLoop.current.add(updateTimer, forMode: .common)
    }
    
    // Calculate the tournament standings
    // TODO: Sort by name if tournament hasn't started yet
    // TODO: Use 5th top athlete as a tie-breaker
    func calculateTournamentStandings() {
        
        var newStandings = [TournamentStanding]()
        
        // Create a tournament standing object for each user
        for user in league.members {
            
            var topAthletes = [Athlete]()
            
            // If user has picked at least one athlete, calculate the top athletes
            if let userPicks = tournament.pickIds[user.id] {
                
                // Fetch the picked athletes
                let athletes = tournament.athletes.filter { userPicks.contains([$0.id]) }
                
                // Sort and copy the top athletes to a new array
                if !athletes.isEmpty {
                    let sortedAthletes = athletes.sorted { $0.score < $1.score }
                    let athleteCount = sortedAthletes.count >= 4 ? 3 : sortedAthletes.count - 1
                    topAthletes = Array(sortedAthletes[0...athleteCount])
                }
            }
            
            // Create and append a new tournament standing to the temporary container
            let userStanding = TournamentStanding(tournamentId: tournament.id, user: user, topAthletes: topAthletes)
            newStandings.append(userStanding)
        }
        
        // Sort the standings
        newStandings = newStandings.sorted(by: <)
        
        //  Format and assign placements
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        newStandings.indices.forEach { newStandings[$0].place = formatter.string(for: $0+1)! }
        
        // Account for ties
        var i = 0
        while i < newStandings.count-1 {
            if newStandings[i].score == newStandings[i+1].score {
                
                // Don't add a 'T' if the place already has one
                if !newStandings[i].place.hasPrefix("T") {
                    newStandings[i].place = "T" + newStandings[i].place
                }
                newStandings[i+1].place = newStandings[i].place
            }
            i += 1
        }
        
        // Save the standings
        standings = newStandings
    }
    
    // Remove tournament data and user associations
    @IBAction func deleteTournamentPressed(_ sender: Any) {
        let deleteTournamentAlert = UIAlertController(title: "Are you sure?", message: "All of the tournament data will be permenantly deleted.", preferredStyle: .alert)
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        let confirm = UIAlertAction(title: "Delete Tournament", style: .destructive) { [unowned deleteTournamentAlert] _ in
            
            // Dismiss the current alert
            deleteTournamentAlert.dismiss(animated: true)
            
            // Remove the tournament data from the tournaments and tournamentIds trees
            self.tournament.databaseReference.removeValue()
            Database.database().reference().child("tournamentIds").child(self.tournament.id).removeValue()
            
            // Remove the tournament data from the league tournamentIds tree
            self.league.databaseReference.child("tournamentIds").child(self.tournament.id).removeValue()
            
            // Return to TournamentsTableViewController
            self.navigationController?.popViewController(animated: true)
        }
        
        deleteTournamentAlert.addAction(cancel)
        deleteTournamentAlert.addAction(confirm)
        
        present(deleteTournamentAlert, animated: true)
    }
    
    // Temporary physical switch to set if tournament has started
    @IBAction func tournamentStartedSwitchToggled() {
        makePicksButton.isEnabled.toggle()
        //tournament.tournamentHasStarted.toggle()
        //tournament.databaseReference.child("tournamentHasStarted").setValue(tournament.tournamentHasStarted)
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
            if let athlete = tournament.athletes.first(where: { $0.id == athleteId }) {
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
        tournament.databaseReference.child("pickIds").child(currentFirebaseUser.uid).setValue(pickDict)
        
        // Save the picks to the local data source
        let pickArray = pickDict.map { $0.key }
        tournament.pickIds[currentFirebaseUser.uid] = pickArray
        
        // Update the tournament standings and refresh the table view
        calculateTournamentStandings()
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
    }
    
    // Remove an existing athlete
    func removeAthlete(athlete: Athlete) {
        tournament.athletes.removeAll { $0.id == athlete.id }
    }
    
    // Update an existing athlete
    func updateAthlete(athlete: Athlete) {
        guard let index = (tournament.athletes.firstIndex { $0.id == athlete.id }) else { return }
        tournament.athletes[index] = athlete
    }
}
