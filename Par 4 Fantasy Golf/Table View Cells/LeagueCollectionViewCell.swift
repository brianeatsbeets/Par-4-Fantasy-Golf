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
    
    @IBOutlet var leagueStandingFirstLabel: UILabel!
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
    let updateInterval: Double = 1*60
    
    override func awakeFromNib() {
        mainContentView.layer.cornerRadius = 12.0
        recentTournamentTimerLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 15, weight: .regular)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Invalidate the timer to prevent multiple timers being created for the same cell when the cell gets recycled
        updateTimer.invalidate()
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
        
        // Recent Tournament
        
        // Calculate and display most recent tournament data
        let recentTournament = league.tournaments.sorted { $0.endDate > $1.endDate }.first!
        recentTournamentNameLabel.text = recentTournament.name
        
        // Update UI based on tournament status
        switch recentTournament.status {
        case .scheduled:
            recentTournamentStatusLabel.text = "Begins \(recentTournament.startDate.formattedDate())"
            recentTournamentStatusLabel.textColor = .black
            recentTournamentTimerLabel.isHidden = true
        case .live:
            recentTournamentStatusLabel.text = "LIVE"
            recentTournamentStatusLabel.textColor = .red
            recentTournamentTimerLabel.isHidden = false
            initializeUpdateTimer(league: league, tournament: recentTournament)
        case .completed:
            recentTournamentStatusLabel.textColor = .black
            recentTournamentTimerLabel.isHidden = true
            
            // If the tournament ended but the last update was before the end of the tournament, pull the final scores
            if recentTournament.lastUpdateTime < recentTournament.endDate {
                delegate?.timerDidReset(league: league, tournament: recentTournament)
                recentTournamentStatusLabel.text = "Fetching final scores..."
            } else {
                recentTournamentStatusLabel.text = "Ended \(recentTournament.endDate.formattedDate())"
            }
        }
        
        // Display the top 3 in the tournament standings
        recentTournamentFirstLabel.text = recentTournament.standings.indices.contains(0) ? "1st: \(recentTournament.standings[0].user.email) (\(recentTournament.standings[0].totalScore.formattedScore()))" : ""
        recentTournamentSecondLabel.text = recentTournament.standings.indices.contains(1) ? "2nd: \(recentTournament.standings[1].user.email) (\(recentTournament.standings[1].totalScore.formattedScore()))" : ""
        recentTournamentThirdLabel.text = recentTournament.standings.indices.contains(2) ? "3rd: \(recentTournament.standings[2].user.email) (\(recentTournament.standings[2].totalScore.formattedScore()))" : ""
        
        // League Standings
        
        // Calculate the current league standings and display the top 3
        let leagueStandings = league.calculateLeagueStandings()
        let standingsKeysSorted = leagueStandings.keys.sorted()
        leagueStandingFirstLabel.text = standingsKeysSorted.indices.contains(0) ? "1st: \(standingsKeysSorted[0]) - \(leagueStandings[standingsKeysSorted[0]]!) win(s)" : ""
        leagueStandingSecondLabel.text = standingsKeysSorted.indices.contains(1) ? "2nd: \(standingsKeysSorted[1]) - \(leagueStandings[standingsKeysSorted[1]]!) win(s)" : ""
        leagueStandingThirdLabel.text = standingsKeysSorted.indices.contains(2) ? "3rd: \(standingsKeysSorted[2]) - \(leagueStandings[standingsKeysSorted[2]]!) win(s)" : ""
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
