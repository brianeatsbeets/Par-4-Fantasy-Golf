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
    func configure(with standing: TournamentStanding, tournamentStarted: Bool) {
        
        if standing.topAthletes.isEmpty {
            accessoryType = .none
        } else {
            accessoryType = .disclosureIndicator
        }
        
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
        
        config.text = "\(standing.place): \(standing.user.email): \(standing.totalScore.formattedScore())" + penaltiesText
        
        // Set the user picks text based on the tournament status
        if tournamentStarted {
            
            // Format the top athletes listing
            let topAthletesFormatted = {
                var text = "Top picks: "
                
                if !standing.topAthletes.isEmpty {
                    for athlete in standing.topAthletes {
                        text.append(athlete.name + ": " + athlete.score.formattedScore())
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
        } else {
            config.secondaryText = "Picks are hidden until tournament begins"
        }
        
        contentConfiguration = config
    }

}
