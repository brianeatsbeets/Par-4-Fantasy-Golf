//
//  League.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 2/28/23.
//

// MARK: - Imported libraries

import Foundation
import FirebaseAuth
import FirebaseDatabase

// MARK: - Main struct

// This model represents a league
struct League: Hashable {
    
    // MARK: - Properties
    
    let id: UUID
    var name: String
    var startDate: Double
    let creator: String
    var memberIds: [String]
    
    // MARK: - Initializers
    
    // Standard init
    init(name: String, startDate: Double, memberIds: [String] = []) {
        id = UUID()
        self.name = name
        self.startDate = startDate
        
        // Set the current user as the creator when creating a new league
        if let user = Auth.auth().currentUser {
            creator = user.email!
        } else {
            creator = "No creator found"
        }
        
        self.memberIds = memberIds
    }
    
    // Init with snapshot data
    init?(snapshot: DataSnapshot) {
        
        // Validate and set the incoming values
        guard let value = snapshot.value as? [String: AnyObject],
              let id = UUID(uuidString: snapshot.key),
              let name = value["name"] as? String,
              let startDate = value["startDate"] as? Double,
              let creator = value["creator"] as? String else { return nil }
        
        self.id = id
        self.name = name
        self.startDate = startDate
        self.creator = creator
        
        if let memberIds = value["memberIds"] as? [String] {
            self.memberIds = memberIds
        } else {
            self.memberIds = []
        }
    }
    
    // MARK: - Functions
    
    // Convert the league to a Dictionary to be stored in Firebase
    func toAnyObject() -> Any {
        return [
            "name": name,
            "startDate": startDate,
            "creator": creator,
            "memberIds": memberIds
        ]
    }
}

// MARK: - Extensions

// This extension houses a date formatting helper function
extension Double {
    func formattedDate() -> String {
        return Date(timeIntervalSince1970: self).formatted(date: .numeric, time: .omitted)
    }
}
