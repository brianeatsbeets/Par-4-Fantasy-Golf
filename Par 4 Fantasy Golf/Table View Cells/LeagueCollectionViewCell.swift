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
        
        let sortedTournaments = league.tournaments.sorted { $0.endDate > $1.endDate }
        
        if let recentTournament = sortedTournaments.first {
            print(recentTournament.name)
            let standings = recentTournament.calculateStandings(league: league)
            recentTournamentFirstLabel.text = standings.indices.contains(0) ? "1st: \(standings[0].user.email) - \(standings[0].formattedScore)" : ""
            recentTournamentSecondLabel.text = standings.indices.contains(1) ? "2nd: \(standings[1].user.email) - \(standings[1].formattedScore)" : ""
            recentTournamentThirdLabel.text = standings.indices.contains(2) ? "3rd: \(standings[2].user.email) - \(standings[2].formattedScore)" : ""
        }
    }

}
