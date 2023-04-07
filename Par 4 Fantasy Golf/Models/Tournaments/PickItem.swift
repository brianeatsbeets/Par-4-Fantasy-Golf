//
//  PickItem.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/25/23.
//

// MARK: - Main struct

// This model represents a pick item, which contains an athlete and whether or not they were selected as a pick for a given user
struct PickItem: Hashable {
    
    // MARK: - Properties
    
    let athlete: Athlete
    var isSelected: Bool
}
