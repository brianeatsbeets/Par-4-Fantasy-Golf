//
//  LeagueCollectionViewCell.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 5/18/23.
//

// MARK: - Imported libraries

import UIKit

// MARK: - Main class

// This class/collection view cell presents a league cell
class LeagueCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    static let reuseIdentifier = "CollectionLeagueCell"
    
    @IBOutlet var titleLabel: UILabel!
    
    @IBOutlet var mainContentView: UIView!
    
    @IBOutlet var leagueStangingFirstLabel: UILabel!
    @IBOutlet var leagueStandingSecondLabel: UILabel!
    @IBOutlet var leagueStandingThirdLabel: UILabel!
    
    @IBOutlet var recentTournamentFirstLabel: UILabel!
    @IBOutlet var recentTournamentSecondLabel: UILabel!
    @IBOutlet var recentTournamentThirdLabel: UILabel!

    
    override func awakeFromNib() {
        mainContentView.layer.cornerRadius = 12.0
    }
    
    // MARK: - Functions

    // Set up the cell UI elements
    //func configure(with league: MinimalLeague) {
    func configure(with league: League) {
//        var config = UIListContentConfiguration.cell()
//        config.text = league.name
//        contentConfiguration = config
//        backgroundColor = .cyan
        
        titleLabel.text = league.name
        
    }

}
