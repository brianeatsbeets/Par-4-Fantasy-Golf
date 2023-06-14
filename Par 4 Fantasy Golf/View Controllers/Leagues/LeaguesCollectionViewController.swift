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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        displayLoadingIndicator(animated: false)
        
        // Fetch initial league data and update the collection view
        fetchLeagueData() {
            self.dismissLoadingIndicator(animated: true)
            self.updateCollectionView()
        }
    }
    
    // MARK: - Other functions
    
    // Fetch league data from the leagueIds tree and store it
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
            cell.configure(with: league)
            
            return cell
        })
    }
    
    // Apply a snapshot with updated league data
    func updateCollectionView(animated: Bool = true) {
        //var snapshot = NSDiffableDataSourceSnapshot<Section, MinimalLeague>()
        var snapshot = NSDiffableDataSourceSnapshot<Section, League>()
        snapshot.appendSections(Section.allCases)
        //snapshot.appendItems(minimalLeagues)
        snapshot.appendItems(leagues)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}
