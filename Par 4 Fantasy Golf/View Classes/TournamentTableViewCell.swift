//
//  TournamentTableViewCell.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 4/5/23.
//

// MARK: - Imported libraries

import UIKit

// MARK: - Main class

// This class/table view cell presents a selectable tournament cell
class TournamentTableViewCell: UITableViewCell {
    
    // MARK: - Properties
    
    // MARK: - Functions

    // Set up the cell UI elements
    func configure(with tournament: Tournament) {
        var config = defaultContentConfiguration()
        config.text = tournament.name
        config.secondaryText = "Start date: \(tournament.startDate.prettyDate()) | End date: \(tournament.endDate.prettyDate())"
        contentConfiguration = config
    }

}
