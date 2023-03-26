//
//  PickItem.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/25/23.
//

// MARK: - Main struct

// Helper struct to contain athlete selection data
struct PickItem: Hashable {
    
    // MARK: - Properties
    
    let athlete: Athlete
    var isSelected: Bool
}
