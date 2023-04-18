//
//  TournamentStandingTableViewCell.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/3/23.
//

// MARK: - Imported libraries

import UIKit

// MARK: - Main class

// This class/table view cell presents a tournament standing cell
class TournamentStandingTableViewCell: UITableViewCell {
    
    // MARK: - Functions
    
    // Set up the cell UI elements
    func configure(with standing: TournamentStanding) {
        
        var config = defaultContentConfiguration()
        let penaltiesText: String = {
            switch standing.penalties {
            case 1:
                return " (1 CUT)"
            case 2...:
                return " (\(standing.penalties) CUTs)"
            default:
                return ""
            }
        }()
        
        config.text = "\(standing.place): \(standing.user.email): \(standing.formattedScore)" + penaltiesText
        
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
