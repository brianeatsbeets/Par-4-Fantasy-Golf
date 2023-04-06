//
//  LeagueDetailTableViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 4/5/23.
//

// MARK: - Imported libraries

import UIKit
import FirebaseAuth
import FirebaseDatabase

// MARK: - Main class

// This class/view controller displays details for the selected league
class LeagueDetailTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    lazy var dataSource = createDataSource()
    var league: League
    let currentFirebaseUser = Auth.auth().currentUser!
    var firstLoad = true
    var calendarEvents = [CalendarEvent]()
    
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
        
        //self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: <#T##Selector?#>)
        
        // If the current user is not the league owner, hide administrative actions
        if league.creator != currentFirebaseUser.email {
            // editLeagueButton.isHidden = true
        }
        
        Task {
            league.members = await User.fetchMultipleUsers(from: self.league.memberIds)
            //calculateLeagueStandings()
            await fetchEspnData()
            updateTableView()
        }
    }
    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//
//        // If this is the first time displaying this view controller, viewDidLoad will handle updating the table view
//        if firstLoad {
//            firstLoad = false
//        } else {
//            calculateLeagueStandings()
//            updateTableView()
//        }
//    }
    
    // MARK: - Other functions
    
    // Fetch ESPN Data
    func fetchEspnData() async {
        // Construct URL
        let url = URL(string: "https://site.api.espn.com/apis/site/v2/sports/golf/pga/scoreboard?dates=20230406")!
        
        do {
            // Request data from the URL
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Make sure we have a valid HTTP response
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let apiResponse = try? JSONDecoder().decode(ServerResponse.self, from: data) {
                
                // Filter the calendar events to those whose end date is later than now
                calendarEvents = apiResponse.activeLeagues[0].calendar.filter({ event in
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withFullDate]
                    guard let eventEndDate = formatter.date(from: event.endDate) else { print("AAA"); return false }
                    
                    return eventEndDate > Date.now
                })
                
                
                
                
                
                //let dictionaryResponse = try? jsonDecoder.decode(Scoreboard.self, from: data) {
                //print("Calendar: \(apiResponse.activeLeagues[0].calendar)")
//                print("Event name: \(apiResponse.activeEvents[0].name)")
//                print("Event id: \(apiResponse.activeEvents[0].id)")
//                print("Event start date: \(apiResponse.activeEvents[0].startDate)")
//                print("Event start date (pretty print): \(apiResponse.activeEvents[0].startDate.prettyDate())")
//                print("Event end date: \(apiResponse.activeEvents[0].endDate)")
//                print("Event status: \(apiResponse.activeEvents[0].competitions[0].status.statusDetails.statusDescription)")
//
//                if let competitors = apiResponse.activeEvents[0].competitions[0].competitors {
//
//                    //print("Event competitors: \(competitors)")
//                    for competitor in competitors {
//
//                        var playerInfo = "\(competitor.nameContainer.name): \(competitor.overallScore)"
//
//                        // Check if competitor has played less rounds than the first place competitor
//                        if competitor.roundScores.count < competitors[0].roundScores.count {
//                            playerInfo += " (PLAYER CUT)"
//                        }
//
//                        print(playerInfo)
//
//                        //                        print("Competitor name: \(competitor.nameContainer.name)")
//                        //                        print("Competitor ID: \(competitor.id)")
//                        //                        print("Competitor overall score: \(competitor.overallScore)")
//                        //                        for (index, round) in competitor.roundScores.enumerated() {
//                        //                            print("Competitor round \(index+1) score: \(round.value)")
//                        //                        }
//                        //                        if competitor.roundScores.count < 3 {
//                        //                            print("PLAYER CUT")
//                        //                        }
//                        //                        print("------------------------------------------------------------")
//                    }
//                } else {
//                    print("No competitors")
//                }
            } else {
                print("HTTP request error: \(response.description)")
            }
        } catch {
            print("Caught error from URLSession.shared.data function")
        }
    }
    
//    // Calculate the league standings
//    // TODO: Sort by name if tournament hasn't started yet
//    // TODO: Use 5th top athlete as a tie-breaker
//    func calculateLeagueStandings() {
//        print("Calculating league standings")
//
//        var newStandings = [LeagueStanding]()
//
//        // Create a league standing object for each user
//        for user in league.members {
//
//            var topAthletes = [Athlete]()
//
//            // If user has picked at least one athlete, calculate the top athletes
//            if let userPicks = league.pickIds[user.id] {
//
//                // Fetch the picked athletes
//                let athletes = league.athletes.filter { userPicks.contains([$0.id]) }
//
//                // Sort and copy the top athletes to a new array
//                if !athletes.isEmpty {
//                    let sortedAthletes = athletes.sorted { $0.score < $1.score }
//                    let athleteCount = sortedAthletes.count >= 4 ? 3 : sortedAthletes.count - 1
//                    topAthletes = Array(sortedAthletes[0...athleteCount])
//                }
//            }
//
//            // Create and append a new league standing to the temporary container
//            let userStanding = LeagueStanding(leagueId: league.id, user: user, topAthletes: topAthletes)
//            newStandings.append(userStanding)
//        }
//
//        // Sort the standings
//        newStandings = newStandings.sorted(by: <)
//
//        //  Format and assign placements
//        let formatter = NumberFormatter()
//        formatter.numberStyle = .ordinal
//        newStandings.indices.forEach { newStandings[$0].place = formatter.string(for: $0+1)! }
//
//        // Account for ties
//        var i = 0
//        while i < newStandings.count-1 {
//            if newStandings[i].score == newStandings[i+1].score {
//
//                // Don't add a 'T' if the place already has one
//                if !newStandings[i].place.hasPrefix("T") {
//                    newStandings[i].place = "T" + newStandings[i].place
//                }
//                newStandings[i+1].place = newStandings[i].place
//            }
//            i += 1
//        }
//
//        // Save the standings
//        standings = newStandings
//    }
    
    // Remove league data and user associations
    @IBAction func deleteLeaguePressed(_ sender: Any) {
        let deleteLeagueAlert = UIAlertController(title: "Are you sure?", message: "All of the league data will be permenantly deleted.", preferredStyle: .alert)
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        let confirm = UIAlertAction(title: "Delete League", style: .destructive) { [unowned deleteLeagueAlert] _ in
            
            // Dismiss the current alert
            deleteLeagueAlert.dismiss(animated: true)
            
            // Remove the league from each user's leagues
            for user in self.league.members {
                user.databaseReference.child("leagues").child(self.league.id).removeValue()
            }
            
            // Remove the league data from the leagues and leagueIds trees
            self.league.databaseReference.removeValue()
            Database.database().reference().child("leagueIds").child(self.league.id).removeValue()
            
            // Return to LeaguesTableViewController
            self.navigationController?.popViewController(animated: true)
        }
        
        deleteLeagueAlert.addAction(cancel)
        deleteLeagueAlert.addAction(confirm)
        
        present(deleteLeagueAlert, animated: true)
    }
    
//    // Temporary physical switch to set if tournament has started
//    @IBAction func tournamentStartedSwitchToggled() {
//        makePicksButton.isEnabled.toggle()
//        league.tournamentHasStarted.toggle()
//        league.databaseReference.child("tournamentHasStarted").setValue(league.tournamentHasStarted)
//    }
    
    // MARK: - Navigation
    
    // Pass league data to CreateTournamentTableViewController
    @IBSegueAction func segueToCreateTournament(_ coder: NSCoder) -> CreateTournamentTableViewController? {
        return CreateTournamentTableViewController(coder: coder, events: calendarEvents)
    }
    
    // Pass league data to TournamentDetailTableViewController
    @IBSegueAction func segueToTournamentDetail(_ coder: NSCoder, sender: Any?) -> TournamentDetailTableViewController? {
        
        // Get the tournament from the tapped cell and pass it
        guard let tournamentCell = sender as? UITableViewCell,
              let indexPath = tableView.indexPath(for: tournamentCell),
              let tournament = dataSource.itemIdentifier(for: indexPath) else { return nil }
        
        return TournamentDetailTableViewController(coder: coder, league: league, tournament: tournament)
    }
    
    
//    // Pass league data to ManageUsersTableViewController
//    @IBSegueAction func segueToManageUsers(_ coder: NSCoder) -> ManageUsersTableViewController? {
//        guard let manageUsersViewController = ManageUsersTableViewController(coder: coder, league: league) else { return nil }
//        manageUsersViewController.delegate = self
//        return manageUsersViewController
//    }
    
//    // Pass league data to MakePicksTableViewController
//    @IBSegueAction func segueToMakePicks(_ coder: NSCoder) -> MakePicksTableViewController? {
//        return MakePicksTableViewController(coder: coder, league: league)
//    }
//
//    // Pass league data to ManageAthletesTableViewController
//    @IBSegueAction func segueToManageAthletes(_ coder: NSCoder) -> ManageAthletesTableViewController? {
//        guard let manageAthletesViewController = ManageAthletesTableViewController(coder: coder, league: league) else { return nil }
//        manageAthletesViewController.delegate = self
//        return manageAthletesViewController
//    }
    
//    // Segue to LeagueUserDetailViewController
//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//
//        tableView.deselectRow(at: indexPath, animated: true)
//
//        // Make sure we have picks for the selected user
//        guard let leagueStanding = dataSource.itemIdentifier(for: indexPath),
//              let userPicks = league.pickIds[leagueStanding.user.id] else { print("No picks for this user"); return }
//
//        var selectedUserPicks = [Athlete]()
//
//        // Grab the athlete object for each athlete Id
//        for athleteId in userPicks {
//            if let athlete = league.athletes.first(where: { $0.id == athleteId }) {
//                selectedUserPicks.append(athlete)
//            } else {
//                print("Error finding athlete from pick: No matching athlete ID found")
//            }
//        }
//
//        // Sort the picked athletes
//        selectedUserPicks = selectedUserPicks.sorted(by: { $0.score < $1.score })
//
//        // Verify we can instantiate an instance of LeagueUserDetailTableViewController
//        guard let destinationViewController = storyboard?.instantiateViewController(identifier: "LeagueUserDetail", creator: { coder in
//            LeagueUserDetailTableViewController(coder: coder, selectedUserEmail: leagueStanding.user.email, selectedUserPicks: selectedUserPicks)
//        }) else { return }
//
//        // Push the new view controller
//        navigationController?.pushViewController(destinationViewController, animated: true)
//    }
    
//    // Handle the incoming new picks data
//    // TODO: Optimize to only write/delete necessary pick data
//    @IBAction func unwindFromMakePicks(segue: UIStoryboardSegue) {
//
//        // Check that we have new picks data to parse
//        guard segue.identifier == "makePicksUnwind",
//              let sourceViewController = segue.source as? MakePicksTableViewController else { return }
//        let pickItems = sourceViewController.pickItems
//
//        // Convert pickItems array to Firebase-style dictionary
//        var pickDict = [String: Bool]()
//        for pick in pickItems {
//            if pick.isSelected {
//                pickDict[pick.athlete.id] = true
//            }
//        }
//
//        // Save the picks to Firebase
//        league.databaseReference.child("pickIds").child(currentFirebaseUser.uid).setValue(pickDict)
//
//        // Save the picks to the local data source
//        let pickArray = pickDict.map { $0.key }
//        league.pickIds[currentFirebaseUser.uid] = pickArray
//
//        // Update the league standings and refresh the table view
//        calculateLeagueStandings()
//        updateTableView()
//    }
    
    // Handle the incoming new tournament data
    @IBAction func unwindFromCreateTournament(segue: UIStoryboardSegue) {
        
        // Check that we have new tournament data to parse
        guard segue.identifier == "unwindCreateTournament",
              let sourceViewController = segue.source as? CreateTournamentTableViewController,
              let selectedEvent = sourceViewController.selectedEvent else { return }
        
        // Save the tournament to the local data source
        let newTournament = Tournament(name: selectedEvent.name, startDate: selectedEvent.startDate, endDate: selectedEvent.endDate, budget: 25)
        league.tournamentIds.append(newTournament.id)
        league.tournaments.append(newTournament)
        
        // Save the tournament to Firebase
        //league.databaseReference.child("tournamentIds").child(newTournament.id).setValue(true)
        //newTournament.databaseReference.setValue(newTournament.toAnyObject())
        
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
    func createDataSource() -> UITableViewDiffableDataSource<Section, Tournament> {
        
        return UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, tournament in
            
            // Configure the cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "LeagueDetailCell", for: indexPath) as! TournamentTableViewCell
            cell.configure(with: tournament)

            return cell
        }
    }
    
    // Apply a snapshot with updated league data
    func updateTableView(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Tournament>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(league.tournaments)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}

//// This extention conforms to the ManageAthletesDelegate protocol
//extension LeagueDetailTableViewController: ManageAthletesDelegate {
//
//    // Add a new athlete
//    func addAthlete(athlete: Athlete) {
//        league.athletes.append(athlete)
//    }
//
//    // Remove an existing athlete
//    func removeAthlete(athlete: Athlete) {
//        league.athletes.removeAll { $0.id == athlete.id }
//    }
//
//    // Update an existing athlete
//    func updateAthlete(athlete: Athlete) {
//        guard let index = (league.athletes.firstIndex { $0.id == athlete.id }) else { return }
//        league.athletes[index] = athlete
//    }
//}

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
