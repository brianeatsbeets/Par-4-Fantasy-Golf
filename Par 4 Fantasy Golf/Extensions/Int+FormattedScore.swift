//
//  Int+FormattedScore.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 7/10/23.
//

import Foundation

// This extension houses a date formatting helper function
extension Int {
    
    // Convert the numerical score into proper golf score formatting
    func formattedScore() -> String {
        switch self {
        case 1...:
            return "+\(self)"
        case ..<0:
            return "\(self)"
        default:
            return "E"
        }
    }
}
