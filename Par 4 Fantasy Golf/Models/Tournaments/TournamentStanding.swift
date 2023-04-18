//
//  TournamentStanding.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/25/23.
//

// MARK: - Main struct

// This model represents a tournament standing, which contains individual user standing data for a given tournament
struct TournamentStanding: Hashable {
    
    // MARK: - Properties
    
    let tournamentId: String
    var place = ""
    let user: User
    var topAthletes: [Athlete]
    var score: Int
    var penalties: Int
    var totalScore: Int {
        score + penalties
    }
    var formattedScore: String {
        switch totalScore {
        case 1...:
            return "+\(totalScore)"
        case ..<0:
            return "\(totalScore)"
        default:
            return "E"
        }
    }
    
    // MARK: - Initializers
    
    init(tournamentId: String, user: User, topAthletes: [Athlete], penalties: Int) {
        self.tournamentId = tournamentId
        self.user = user
        self.topAthletes = topAthletes
        score = topAthletes.reduce(0) { $0 + $1.score }
        self.penalties = penalties
    }
}

// MARK: - Extensions

// This extension conforms to the Comparable protocol
extension TournamentStanding: Comparable {
    static func < (lhs: TournamentStanding, rhs: TournamentStanding) -> Bool {
        lhs.score < rhs.score
    }
}
