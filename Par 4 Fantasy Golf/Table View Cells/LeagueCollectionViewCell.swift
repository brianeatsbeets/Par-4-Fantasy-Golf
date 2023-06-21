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
    
    static let reuseIdentifier = "CollectionLeagueCell"
    
    @IBOutlet var titleLabel: UILabel!
    
    @IBOutlet var mainContentView: UIView!
    
    @IBOutlet var leagueDetailsStackView: UIStackView!
    @IBOutlet var noDataLabel: UILabel!
    
    @IBOutlet var leagueStangingFirstLabel: UILabel!
    @IBOutlet var leagueStandingSecondLabel: UILabel!
    @IBOutlet var leagueStandingThirdLabel: UILabel!
    
    @IBOutlet var recentTournamentNameLabel: UILabel!
    @IBOutlet var recentTournamentStatusLabel: UILabel!
    @IBOutlet var recentTournamentTimerLabel: UILabel!
    
    @IBOutlet var recentTournamentFirstLabel: UILabel!
    @IBOutlet var recentTournamentSecondLabel: UILabel!
    @IBOutlet var recentTournamentThirdLabel: UILabel!
    
    var updateTimer = Timer()
    
    weak var delegate: TournamentTimerDelegate?

    // Timer update interval in seconds
    let updateInterval: Double = 15*60
    
    override func awakeFromNib() {
        mainContentView.layer.cornerRadius = 12.0
        recentTournamentTimerLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 15, weight: .regular)
    }
    
    // MARK: - Functions

    // Set up the cell UI elements
    func configure(with league: League) {
        
        titleLabel.text = league.name
        
        // Make sure we have a tournament to display; otherwise, display the 'No data' message
        guard !league.tournaments.isEmpty else {
            leagueDetailsStackView.isHidden = true
            noDataLabel.isHidden = false
            return
        }
        
        // Set default UI values
        leagueDetailsStackView.isHidden = false
        noDataLabel.isHidden = true
        
        // Calculate and display most recent tournament data
        let recentTournament = league.tournaments.sorted { $0.endDate > $1.endDate }.first!
        recentTournamentNameLabel.text = recentTournament.name
        
        if recentTournament.endDate < Date.now.timeIntervalSince1970 {
            recentTournamentStatusLabel.text = "Ended \(recentTournament.endDate.formattedDate())"
            recentTournamentTimerLabel.isHidden = true
        } else {
            recentTournamentStatusLabel.text = "LIVE"
            recentTournamentStatusLabel.textColor = .red
            initializeUpdateTimer(league: league, tournament: recentTournament)
        }
        
        // TODO: Hide text fields if not in use
        let standings = recentTournament.calculateStandings(league: league)
        recentTournamentFirstLabel.text = standings.indices.contains(0) ? "1st: \(standings[0].user.email) (\(standings[0].formattedScore))" : ""
        recentTournamentSecondLabel.text = standings.indices.contains(1) ? "2nd: \(standings[1].user.email) (\(standings[1].formattedScore))" : ""
        recentTournamentThirdLabel.text = standings.indices.contains(2) ? "3rd: \(standings[2].user.email) (\(standings[2].formattedScore))" : ""
    }
    
    // Set up the update countdown timer
    func initializeUpdateTimer(league: League, tournament: Tournament) {
        
        // Create a string formatter to display the time how we want
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        
        var nextUpdateTime = Date.now.addingTimeInterval(updateInterval).timeIntervalSince1970
        var timeLeft: Int {
            Int((nextUpdateTime - Date.now.timeIntervalSince1970).rounded())
        }
        
        // Check if we're past due for an update
        if tournament.lastUpdateTime < Date.now.addingTimeInterval(-updateInterval).timeIntervalSince1970 {
            
            self.recentTournamentTimerLabel.text = "Updating..."
            
            // Call the delegate function
            self.delegate?.timerDidReset(league: league, tournament: tournament)
            
            return
        } else {
            nextUpdateTime = tournament.lastUpdateTime + (updateInterval)
        }
        
        // Update countdown with initial value before timer starts
        var formattedTime = formatter.string(from: TimeInterval(timeLeft))!
        recentTournamentTimerLabel.text = "Next update in \(formattedTime)"
        
        // Create the timer
        updateTimer = Timer(timeInterval: 1, repeats: true) { timer in
            
            // Check if the countdown has completed
            if timeLeft < 1 {
                //nextUpdateTime = Date.now.addingTimeInterval(self.updateInterval*60).timeIntervalSince1970
                timer.invalidate()
                self.recentTournamentTimerLabel.text = "Updating..."
                
                // Call the delegate function
                self.delegate?.timerDidReset(league: league, tournament: tournament)
            } else {
                
                // Format and present the time remaining until the next update
                formattedTime = formatter.string(from: TimeInterval(timeLeft))!
                self.recentTournamentTimerLabel.text = "Next update in \(formattedTime)"
            }
        }
        
        // Add the timer to the .common runloop so it will update during user interaction
        RunLoop.current.add(updateTimer, forMode: .common)
    }

}
