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
    
    static let reuseIdentifier = "PromotedAppCollectionViewCell"
    
    // MARK: - Functions

    // Set up the cell UI elements
    func configure(with league: MinimalLeague) {
        var config = UIListContentConfiguration.cell()
        config.text = league.name
        contentConfiguration = config
        backgroundColor = .cyan
    }

}
