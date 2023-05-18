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

private let reuseIdentifier = "CollectionLeagueCell"

// MARK: - Main class

// This class/view controller displays available leagues
class LeaguesCollectionViewController: UICollectionViewController {
    
    // MARK: - Properties
    
    lazy var dataSource = createDataSource()
    var minimalLeagues = [MinimalLeague]()
    let leagueIdsRef = Database.database().reference(withPath: "leagueIds")
    let userLeaguesRef = Database.database().reference(withPath: "users/\(Auth.auth().currentUser!.uid)/leagues")
    
    // MARK: - View life cycle functions

    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.collectionViewLayout = createLayout()

        // Register cell classes
        //self.collectionView!.register(LeagueCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        collectionView.dataSource = dataSource
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        displayLoadingIndicator(animated: false)
        
        // Fetch initial league data and update the collection view
        fetchMinimalLeagueData() {
            self.dismissLoadingIndicator(animated: true)
            self.updateCollectionView()
        }
    }
    
    // MARK: - Other functions
    
    // Fetch league data from the leagueIds tree and store it
    func fetchMinimalLeagueData(completion: @escaping () -> Void) {
        
        // Fetch user league Ids
        userLeaguesRef.observeSingleEvent(of: .value) { snapshot in
            guard let userLeagueIdValues = snapshot.value as? [String: Bool] else {
                completion()
                return
            }
            
            let userLeagueIds = userLeagueIdValues.map { $0.key }
            
            // Fetch minimal leagues from user league Ids
            Task {
                self.minimalLeagues = await MinimalLeague.fetchMultipleLeagues(from: userLeagueIds)
                
                // Sort leagues
                self.minimalLeagues = self.minimalLeagues.sorted(by: { $0.name > $1.name})
                completion()
            }
        }
    }
    
    func createLayout() -> UICollectionViewLayout {
        
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            
            // Define header item
            //let headerItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.92), heightDimension: .estimated(44))
            //let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerItemSize, elementKind: SupplementaryViewKind.header, alignment: .top)
            
            // MARK: Promoted Section Layout
            
            // Define item
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalWidth(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4)
            
            // Define group
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.92), heightDimension: .estimated(300))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            // Define section
            let section = NSCollectionLayoutSection(group: group)
            // Set horizontal scroll behavior
            section.orthogonalScrollingBehavior = .groupPagingCentered
            // Set content insets (affects boundary supplementaty items)
            section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 20, trailing: 0)
            
            
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
            
            // Save the minimal league to the local data source
            minimalLeagues.append(minimalLeague)
            minimalLeagues = minimalLeagues.sorted(by: { $0.name > $1.name})
            
            updateCollectionView()
            
            dismissLoadingIndicator(animated: true)
        }
    }
    
    // Segue to LeagueDetailViewController with full league data
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        displayLoadingIndicator(animated: true)
        
        // Fetch the league data from the tapped league's id
        Task {
            guard let minimalLeague = dataSource.itemIdentifier(for: indexPath),
                  var league = await League.fetchSingleLeague(from: minimalLeague.id) else { return }
            
            // Fetch the league members
            league.members = await User.fetchMultipleUsers(from: league.memberIds)
            
            guard let destinationViewController = storyboard?.instantiateViewController(identifier: "LeagueDetail", creator: { coder in
                LeagueDetailTableViewController(coder: coder, league: league)
            }) else { return }
            
            // Deselect the row and push the league details view controller while passing the full league data
            collectionView.deselectItem(at: indexPath, animated: true)
            self.navigationController?.pushViewController(destinationViewController, animated: true)
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

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
    func createDataSource() -> UICollectionViewDiffableDataSource<Section, MinimalLeague> {
        
        print("createDataSource")
        
        return UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, league in
            
            // Configure the cell
            let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! LeagueCollectionViewCell
            cell.configure(with: league)
            
            return cell
        }
    }
    
    // Apply a snapshot with updated league data
    func updateCollectionView(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, MinimalLeague>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(minimalLeagues)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}
