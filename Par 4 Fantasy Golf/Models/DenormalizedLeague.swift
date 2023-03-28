//
//  DenormalizedLeague.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/27/23.
//

import FirebaseDatabase

// MARK: - Main struct

// Helper struct to contain athlete selection data
struct DenormalizedLeague: Hashable {
    
    // MARK: - Properties
    
    let id: String
    var name: String
    var startDate: Double
    
    // MARK: - Initializers
    
    init(id: String, name: String, startDate: Double) {
        self.id = id
        self.name = name
        self.startDate = startDate
    }
    
    // Init with snapshot data
    init?(snapshot: DataSnapshot) {
        
        // Validate and set the incoming values
        guard let snapshotValue = snapshot.value as? [String: AnyObject],
              let name = snapshotValue["name"] as? String,
              let startDate = snapshotValue["startDate"] as? Double else { return nil }

        self.id = snapshot.key
        self.name = name
        self.startDate = startDate
    }
    
    // MARK: - Functions
    
    // Convert the DenormalizedLeague to a Dictionary to be stored in Firebase
    func toAnyObject() -> Any {
        return [
            "name": name,
            "startDate": startDate
        ]
    }
}
