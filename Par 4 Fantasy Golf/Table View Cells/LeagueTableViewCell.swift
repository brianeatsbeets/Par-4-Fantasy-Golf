//
//  LeagueTableViewCell.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/2/23.
//

// MARK: - Imported libraries

import UIKit

// MARK: - Main class

// This class/table view cell presents a league cell
class LeagueTableViewCell: UITableViewCell {
    
    // MARK: - Functions

    // Set up the cell UI elements
    func configure(with league: MinimalLeague) {
        var config = defaultContentConfiguration()
        config.text = league.name
        contentConfiguration = config
    }

}
