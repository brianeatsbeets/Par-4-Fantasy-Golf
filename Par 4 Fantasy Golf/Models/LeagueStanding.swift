//
//  LeagueStanding.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/25/23.
//

// MARK: - Main struct

// Helper struct to contain individual user standing data for a given league
struct LeagueStanding: Hashable {
    
    // MARK: - Properties
    
    let leagueId: String
    let user: User
    var topAthletes: [Athlete]
    var score: Int
    var formattedScore: String {
        switch score {
        case 1...:
            return "+\(score)"
        case ..<0:
            return "\(score)"
        default:
            return "E"
        }
    }
    
    // MARK: - Initializers
    
    init(leagueId: String, user: User, topAthletes: [Athlete]) {
        self.leagueId = leagueId
        self.user = user
        self.topAthletes = topAthletes
        score = topAthletes.reduce(0) { $0 + $1.score }
    }
}

// MARK: - Extensions

// This extension conforms to the Comparable protocol
extension LeagueStanding: Comparable {
    static func < (lhs: LeagueStanding, rhs: LeagueStanding) -> Bool {
        lhs.score < rhs.score
    }
}
