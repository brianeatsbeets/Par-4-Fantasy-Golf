//
//  League.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 2/28/23.
//

// MARK: - Imported libraries

import Foundation

// MARK: - Main struct

// This model represents a league
struct League {
    
    // MARK: - Properties
    
    let id: UUID
    var name: String
    var startDate: Date
    // let creatorId: String
    // var userIds: [String]
    
    // MARK: - Functions
    
    // Convert the league to a Dictionary to be stored in Firebase
    func toAnyObject() -> Any {
        
        // Initialize a data formatter with the appropriate format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/YY"
        
        return [
            "name": name,
            "startDate": dateFormatter.string(from: startDate)
        ]
    }
}
