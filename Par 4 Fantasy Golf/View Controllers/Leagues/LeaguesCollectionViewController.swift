//
//  LeaguesCollectionViewController.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 5/18/23.
//

// MARK: - Imported libraries

import UIKit
import FirebaseAuth
import FirebaseDatabase
import Combine

// MARK: - Protocols

// This protocol allows conformers to be notified when a tournament update timer has reset (hit zero)
protocol TournamentTimerDelegate: AnyObject {
    func timerDidReset(league: League, tournament: Tournament)
}

// MARK: - Main class

// This class/view controller displays available leagues
class LeaguesCollectionViewController: UICollectionViewController {
    
    // MARK: - Properties
    
    lazy var dataSource = createDataSource()
    
    var leagues = [League]()
    var dataStore = DataStore()
    
    let userLeaguesRef = Database.database().reference(withPath: "users/\(Auth.auth().currentUser!.uid)/leagues")
    
    var subscription: AnyCancellable?
    

    // MARK: - View life cycle functions

    override func viewDidLoad() {
        super.viewDidLoad()
        
        displayLoadingIndicator(animated: false)
        
        collectionView.collectionViewLayout = createLayout()
        collectionView.dataSource = dataSource
        
        subscribeToDataStore()

        // Fetch league data from firebase and update the collection view
        fetchLeagueData() {
            
            self.dismissLoadingIndicator(animated: true)
            self.updateCollectionView()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateCollectionView(animated: false)
    }
    
    // MARK: - Other functions
    
    // Create a subscription for the datastore
    func subscribeToDataStore() {

        // Assign a subscription to the variable
        subscription = dataStore.$leagues.sink(receiveCompletion: { _ in
            print("Completion")
        }, receiveValue: { [weak self] leagues in
            print("LeaguesCollectionVC received updated value for leagues")
            
            // Update VC local leagues variable
            // Using weak self to avoid strong reference cycle
            self?.leagues = leagues
        })
    }
    
    // Initialize the collection view layout
    func createLayout() -> UICollectionViewLayout {
        
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            
            // Define item
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 40, leading: 6, bottom: 0, trailing: 6)
            
            let screenHeight = UIScreen.main.bounds.height
            
            // Define group
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.92), heightDimension: .estimated(screenHeight * 0.65))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            // Define section
            let section = NSCollectionLayoutSection(group: group)
            // Set horizontal scroll behavior
            section.orthogonalScrollingBehavior = .groupPagingCentered
            
            return section
        }
        
        return layout
    }
    
    // Fetch league data from the firebase and store it
    func fetchLeagueData(completion: @escaping () -> Void) {
        
        // Fetch user league Ids
        userLeaguesRef.observeSingleEvent(of: .value) { [weak self] snapshot in
            
            // Make sure self is still allocated; otherwise, cancel the operation
            guard let self,
                  let userLeagueIdValues = snapshot.value as? [String: Bool] else {
                completion()
                return
            }
            
            let userLeagueIds = userLeagueIdValues.map { $0.key }
            
            var newLeagues = [League]()
            
            // Fetch leagues from user league Ids
            // TODO: Send out league fetch requests concurrently
            Task {
                for var league in await League.fetchMultipleLeagues(from: userLeagueIds) {
                    league.members = await User.fetchMultipleUsers(from: league.memberIds)
                    league.tournaments = await Tournament.fetchMultipleTournaments(from: league.tournamentIds)
                    
                    // Calculate tournament standings
                    league.tournaments.indices.forEach { index in
                        league.tournaments[index].standings = league.tournaments[index].calculateStandings(leagueMembers: league.members)
                    }
                    
                    newLeagues.append(league)
                }
                
                // Sort leagues alphabetically (case-insensitive)
                self.dataStore.leagues = newLeagues.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
                completion()
            }
        }
    }
    
    // Fetch the updated score data for a given tournament
    func fetchScoreData(league: League, tournament: Tournament) async throws -> [Athlete] {
        var updatedAthleteData = [Athlete]()
        
        // Attempt to fetch updated athlete data
        do {
            updatedAthleteData = try await Tournament.fetchEventAthleteData(eventId: tournament.espnId)
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
        
        var athletes = [Athlete]()
        var nonMatchingAthletes = [Athlete]()
        
        // Merge the new athlete data with the current data
        athletes = tournament.athletes.map({ athlete in
            
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
        if !nonMatchingAthletes.isEmpty && tournament.creator == Auth.auth().currentUser!.email {
            let nonMatchingAthletesString = nonMatchingAthletes.map{ "\($0.name)" }.joined(separator: "\n")
            self.displayAlert(title: "Mismatched Athlete IDs", message:
                                "One or more athletes have incorrect ESPN IDs, so score data for those athletes could not be updated. Instructions on finding the correct ID are listed under the ESPN ID field for the athlete in the Manage Athletes page.\n\nLeague: \(league.name)\nTournament: \(tournament.name)\n\nAffected athletes:\n\(nonMatchingAthletesString)"
            )
        }
        
        return athletes
    }
    
    // MARK: - Navigation
    
    // Handle the incoming new league data
    @IBAction func unwindFromCreateLeague(segue: UIStoryboardSegue) {
        
        // Check that we have new league data to parse
        guard segue.identifier == "createLeagueUnwind",
              let sourceViewController = segue.source as? CreateLeagueTableViewController,
              var league = sourceViewController.league
        else { return }
        
        Task {
            // Save the league to the leagues tree in Firebase
            try await league.databaseReference.setValue(league.toAnyObject())
            
            // Save the league to the league members' data
            for id in league.memberIds {
                try await Database.database().reference(withPath: "users").child(id).child("leagues").child(league.id).setValue(true)
            }
            
            // Create league users
            league.members = await User.fetchMultipleUsers(from: league.memberIds)
            
            // Save the league to the local data source
            dataStore.leagues.append(league)
            
            // Sort the leagues alphabetically (case-insensitive)
            dataStore.leagues = dataStore.leagues.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
            
            updateCollectionView()
            
            dismissLoadingIndicator(animated: true)
        }
    }
    
    // Handle the league that was deleted
    @IBAction func unwindFromDeleteLeague(segue: UIStoryboardSegue) {
        
        // Check that we have league data to delete
        guard segue.identifier == "deleteLeagueUnwind",
              let sourceViewController = segue.source as? LeagueDetailTableViewController else { return }
        
        let league = sourceViewController.league
        
        // Remove the league from the dataStore
        dataStore.leagues.removeAll { $0.id == league.id }
        
        // Remove the league from each user's leagues in firebase
        for user in league.members {
            user.databaseReference.child("leagues").child(league.id).removeValue()
        }
        
        // Remove each tournament in the league in firebase
        for id in league.tournamentIds {
            Database.database().reference().child("tournaments").child(id).removeValue()
        }
        
        // Remove the league data from the leagues tree
        league.databaseReference.removeValue()
        
        updateCollectionView()
    }
    
    // Segue to LeagueDetailViewController with full league data
    // TODO: Revert back to segue action instead of manually pushing
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let league = dataSource.itemIdentifier(for: indexPath),
              let leagueIndex = self.dataStore.leagues.firstIndex(where: { $0.id == league.id }),
              let destinationViewController = storyboard?.instantiateViewController(identifier: "LeagueDetail", creator: { coder in
                  LeagueDetailTableViewController(coder: coder, dataStore: self.dataStore, leagueIndex: leagueIndex)
              }) else { return }
        
        // Deselect the row and push the league details view controller while passing the full league data
        collectionView.deselectItem(at: indexPath, animated: true)
        navigationController?.pushViewController(destinationViewController, animated: true)
    }
}

// MARK: - Extensions

// This extention houses collection view management functions that utilize the diffable data source API
extension LeaguesCollectionViewController {
    
    // MARK: - Section enum
    
    // This enum declares collection view sections
    enum Section: CaseIterable {
        case one
    }
    
    // MARK: - Other functions
    
    // Create the the data source and specify what to do with a provided cell
    func createDataSource() -> UICollectionViewDiffableDataSource<Section, League> {
        
        return .init(collectionView: collectionView, cellProvider: { [weak self] (collectionView, indexPath, league) -> LeagueCollectionViewCell? in
            
            // Configure the cell
            let cell = self?.collectionView.dequeueReusableCell(withReuseIdentifier: LeagueCollectionViewCell.reuseIdentifier, for: indexPath) as! LeagueCollectionViewCell
            cell.delegate = self
            cell.configure(with: league)
            
            return cell
        })
    }
    
    // Apply a snapshot with updated league data
    func updateCollectionView(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, League>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(leagues)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}

// This extention conforms to the TournamentTimerDelegate protocol
extension LeaguesCollectionViewController: TournamentTimerDelegate {
    
    // When a league's timer when it hits zero, fetch updated score data
    func timerDidReset(league: League, tournament: Tournament) {
        
        let sortedTournaments = league.tournaments.sorted { $0.endDate > $1.endDate }

        // Calculate the indexes of the provided league and tournament
        guard let leagueIndex = leagues.firstIndex(of: league),
              let recentTournament = sortedTournaments.first,
              let tournamentIndex = league.tournaments.firstIndex(of: recentTournament) else {
            print("Couldn't determine most recent tournament to update timer")
            return
        }
        
        // Update a copy of the tournament to avoid updating the data store multiple times
        var tournament = leagues[leagueIndex].tournaments[tournamentIndex]
        
        // Update tournament's last update time
        tournament.lastUpdateTime = Date.now.timeIntervalSince1970
        tournament.databaseReference.child("lastUpdateTime").setValue(Date.now.timeIntervalSince1970)
        
        Task {
            
            // Fetch updated tournament data
            tournament.athletes = try await self.fetchScoreData(league: league, tournament: tournament)
            
            // Update the tournament standings
            tournament.standings = tournament.calculateStandings(leagueMembers: league.members)
            
            // Update the data store
            self.dataStore.leagues[leagueIndex].tournaments[tournamentIndex] = tournament
            
            // Update the UI
            self.updateCollectionView()
            
            // Update athlete data in firebase
            try await tournament.databaseReference.setValue(tournament.toAnyObject())
        }
    }
}
