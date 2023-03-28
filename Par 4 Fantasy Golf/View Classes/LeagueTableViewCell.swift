//
//  LeagueTableViewCell.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/2/23.
//

// MARK: - Imported libraries

import UIKit

// MARK: - Main class

// This class/table view cell presents a selectable league cell
class LeagueTableViewCell: UITableViewCell {
    
    // MARK: - Properties
    
    // MARK: - Functions

    // Set up the cell UI elements
    func configure(with league: DenormalizedLeague) {
        var config = defaultContentConfiguration()
        config.text = league.name
        config.secondaryText = "Start date: " + league.startDate.formattedDate()
        contentConfiguration = config
    }

}
