//
//  PickTableViewCell.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/23/23.
//

// MARK: - Imported libraries

import UIKit

// MARK: - Main class

// This class/table view cell presents a league pick cell
class PickTableViewCell: UITableViewCell {
    
    // MARK: - Functions
    
    // Set up the cell UI elements
    func configure(with pickItem: PickItem) {
        var config = defaultContentConfiguration()
        config.text = "\(pickItem.athlete.name)"
        config.secondaryText = "Odds: \(pickItem.athlete.odds) | Selected: \(pickItem.isSelected.description)"
        contentConfiguration = config
        
        if pickItem.isSelected {
            if traitCollection.userInterfaceStyle == .light {
                backgroundColor = UIColor(red: 202/255, green: 1, blue: 196/255, alpha: 1)
            } else {
                backgroundColor = UIColor(red: 39/255, green: 84/255, blue: 41/255, alpha: 1)
            }
        } else {
            backgroundColor = .systemBackground
        }
    }
}
