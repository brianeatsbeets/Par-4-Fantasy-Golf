//
//  LeagueStanding.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 7/24/23.
//

// MARK: - Main struct

// This model represents a league standing, which contains individual user standing data for a given league
struct LeagueStanding: Hashable {
    
    // MARK: - Properties
    
    let user: User
    var score: Int
    
    // MARK: - Initializers
    
    init(user: User, score: Int) {
        self.user = user
        self.score = score
    }
}

// MARK: - Extensions

// This extension conforms to the Comparable protocol
extension LeagueStanding: Comparable {
    static func < (lhs: LeagueStanding, rhs: LeagueStanding) -> Bool {
        lhs.score > rhs.score
    }
}
