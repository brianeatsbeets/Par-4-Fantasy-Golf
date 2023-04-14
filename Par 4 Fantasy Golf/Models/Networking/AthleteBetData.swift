//
//  AthleteBetData.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 4/14/23.
//

import Foundation

// MARK: - Main struct

// This model represents an athlete's betting data to be imported
struct AthleteBetData: Codable {
    
    // MARK: - Properties
    
    let espnId: String
    let name: String
    let odds: String
    let value: String
}
