//
//  LeagueStandingTableViewCell.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/3/23.
//

// MARK: - Imported libraries

import UIKit

// MARK: - Main class

// This class/table view cell presents a league standing cell
class LeagueStandingTableViewCell: UITableViewCell {
    
    // MARK: - Properties
    
    // MARK: - Functions
    
    // Set up the cell UI elements
    func configure(with user: User) {
        var config = defaultContentConfiguration()
        config.text = user.email
        contentConfiguration = config
    }

}
