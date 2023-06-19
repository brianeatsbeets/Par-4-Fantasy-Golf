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

// MARK: - Protocols
protocol TournamentTimerDelegate: AnyObject {
    func timerDidReset(league: League, tournament: Tournament)
}

// MARK: - Main class

// This class/view controller displays available leagues
class LeaguesCollectionViewController: UICollectionViewController {
    
    // MARK: - Properties
    
    lazy var dataSource = createDataSource()
    var minimalLeagues = [MinimalLeague]()
    var leagues = [League]()
    let leagueIdsRef = Database.database().reference(withPath: "leagueIds")
    let userLeaguesRef = Database.database().reference(withPath: "users/\(Auth.auth().currentUser!.uid)/leagues")
    
    // MARK: - View life cycle functions

    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.collectionViewLayout = createLayout()
        collectionView.dataSource = dataSource
        
        displayLoadingIndicator(animated: false)

        // Fetch initial league data and update the collection view
        fetchLeagueData() {
            self.dismissLoadingIndicator(animated: true)
            self.updateCollectionView()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    // MARK: - Other functions
    
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
        userLeaguesRef.observeSingleEvent(of: .value) { snapshot in
            guard let userLeagueIdValues = snapshot.value as? [String: Bool] else {
                completion()
                return
            }
            
            let userLeagueIds = userLeagueIdValues.map { $0.key }
            
            self.leagues = [League]()
            
            // Fetch leagues from user league Ids
            // TODO: Send out league fetch request concurrently
            Task {
                for var league in await League.fetchMultipleLeagues(from: userLeagueIds) {
                    league.members = await User.fetchMultipleUsers(from: league.memberIds)
                    league.tournaments = await Tournament.fetchMultipleTournaments(from: league.tournamentIds)
                    self.leagues.append(league)
                }
                
                // Sort leagues
                self.leagues = self.leagues.sorted(by: { $0.name > $1.name})
                completion()
            }
        }
    }
    
    // Fetch the updated score data for a given tournament
    func fetchScoreData(tournament: Tournament) async throws -> [Athlete] {
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
            let nonMatchingAthletesString = nonMatchingAthletes.map{ "\($0.name) (ESPN ID: \($0.espnId))" }.joined(separator: "\n")
            self.displayAlert(title: "Mismatched Athlete IDs", message: "One or more athletes have incorrect ESPN IDs, so score data for those athletes could not be updated. Please correct their ESPN IDs in the Manage Athletes view.\n\nAffected athletes:\n\(nonMatchingAthletesString)")
        }
        
        return athletes
    }
    
    // MARK: - Navigation
    
    // Handle the incoming new league data
    @IBAction func unwindFromCreateLeague(segue: UIStoryboardSegue) {
        
        // Check that we have new league data to parse
        guard segue.identifier == "createLeagueUnwind",
              let sourceViewController = segue.source as? CreateLeagueTableViewController,
              let league = sourceViewController.league
        else { return }
        
        let minimalLeague = MinimalLeague(league: league)
        
        Task {
            // Save the league to the leagues tree in Firebase
            try await league.databaseReference.setValue(league.toAnyObject())
            
            // Save the league to the leagueIds tree in Firebase
            try await leagueIdsRef.child(league.id).setValue(minimalLeague.toAnyObject())
            
            // Save the league to the league members' data
            for id in league.memberIds {
                try await Database.database().reference(withPath: "users").child(id).child("leagues").child(league.id).setValue(true)
            }
            
            // Save the league to the local data source
            leagues.append(league)
            leagues = leagues.sorted(by: { $0.name > $1.name})
            
            updateCollectionView()
            
            dismissLoadingIndicator(animated: true)
        }
    }
    
    // Segue to LeagueDetailViewController with full league data
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let league = dataSource.itemIdentifier(for: indexPath),
              let destinationViewController = storyboard?.instantiateViewController(identifier: "LeagueDetail", creator: { coder in
                  LeagueDetailTableViewController(coder: coder, league: league)
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
        
        return .init(collectionView: collectionView, cellProvider: { (collectionView, indexPath, league) -> LeagueCollectionViewCell? in
            
            // Configure the cell
            let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: LeagueCollectionViewCell.reuseIdentifier, for: indexPath) as! LeagueCollectionViewCell
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
        
        // Create value (not reference) copies to minimize array lookups when referencing tournament data, but not updating it
        let leagueRef = leagues[leagueIndex]
        let tournamentRef = leagueRef.tournaments[tournamentIndex]
        
        // Update tournament's last update time
        self.leagues[leagueIndex].tournaments[tournamentIndex].lastUpdateTime = Date.now.timeIntervalSince1970
        tournamentRef.databaseReference.child("lastUpdateTime").setValue(Date.now.timeIntervalSince1970)
        
        // Fetch updated tournament data and update UI
        Task {
            self.leagues[leagueIndex].tournaments[tournamentIndex].athletes = try await self.fetchScoreData(tournament: tournamentRef)
            
            self.updateCollectionView()
            
            // Update athlete data in firebase
            try await tournamentRef.databaseReference.setValue(self.leagues[leagueIndex].tournaments[tournamentIndex].toAnyObject())
        }
    }
}
