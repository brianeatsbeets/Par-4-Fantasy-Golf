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
    
    // MARK: - Properties
    
    // MARK: - Functions
    
    // Set up the cell UI elements
    func configure(with pickItem: PickItem) {
        var config = defaultContentConfiguration()
        config.text = pickItem.athlete
        config.secondaryText = pickItem.isSelected.description
        contentConfiguration = config
    }

}
