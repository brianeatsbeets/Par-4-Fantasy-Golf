//
//  Double+FormattedDate.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 6/22/23.
//

import Foundation

// This extension houses a date formatting helper function
extension Double {
    
    // Convert the epoch date into a human-readable format
    func formattedDate() -> String {
        return Date(timeIntervalSince1970: self).formatted(date: .numeric, time: .omitted)
    }
}
