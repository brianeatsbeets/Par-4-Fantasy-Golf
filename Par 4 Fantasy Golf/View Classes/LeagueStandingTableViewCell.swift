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
    func configure(with standing: LeagueStanding) {
        
        var config = defaultContentConfiguration()
        config.text = "\(standing.place): \(standing.user.email): \(standing.formattedScore)"
        
        // Format the top athletes listing
        let topAthletesFormatted = {
            var text = "Top picks: "
            
            if !standing.topAthletes.isEmpty {
                for athlete in standing.topAthletes {
                    text.append(athlete.name + ": " + athlete.formattedScore)
                    if athlete != standing.topAthletes.last {
                        text.append(" | ")
                    }
                }
            } else {
                text = "No picks made"
            }
            
            return text
        }()
        
        config.secondaryText = topAthletesFormatted
        contentConfiguration = config
    }

}
