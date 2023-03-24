//
//  Athlete.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/23/23.
//

// MARK: - Imported libraries

import FirebaseDatabase

// MARK: - Main struct

// This model represents an athlete
struct Athlete: Hashable {
    
    // MARK: - Properties
    
    let id: UUID
    var name: String
    var odds: Int
    var value: Int
    
    // MARK: - Initializers
    
    // Standard init
    init(id: UUID = UUID(), name: String, odds: Int, value: Int) {
        self.id = id
        self.name = name
        self.odds = odds
        self.value = value
    }
    
    // Init with snapshot data
    init?(snapshot: DataSnapshot) {
        
        // Validate and set the incoming values
        guard let value = snapshot.value as? [String: AnyObject],
              let id = UUID(uuidString: snapshot.key),
              let name = value["name"] as? String,
              let odds = value["odds"] as? Int,
              let value = value["value"] as? Int else { return nil }
        
        self.id = id
        self.name = name
        self.odds = odds
        self.value = value
    }
    
    // MARK: - Functions
    
    // Convert the athlete to a Dictionary to be stored in Firebase
    func toAnyObject() -> Any {
        return [
            "name": name,
            "odds": odds,
            "value": value
        ]
    }
}
