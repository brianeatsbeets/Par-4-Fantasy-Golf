//
//  User.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/3/23.
//

// MARK: - Imported libraries

import Foundation
import FirebaseAuth
import FirebaseDatabase

// MARK: - Main struct

// This model represents a user
struct User: Hashable {
    
    // MARK: - Properties
    
    let id: String
    var email: String
    //var username: String
    
    // MARK: - Initializers
    
    // Standard init
    init(id: String, email: String) {
        self.id = id
        self.email = email
    }
    
    // Init with snapshot data
    init?(snapshot: DataSnapshot) {
        
        // Validate and set the incoming values
        guard let value = snapshot.value as? [String: AnyObject],
              let email = value["email"] as? String else { return nil }
        
        self.id = snapshot.key
        self.email = email
    }
    
    // MARK: - Functions
    
    // Convert the user to a Dictionary to be stored in Firebase
    func toAnyObject() -> Any {
        
        return [
            //"id": id.uuidString,
            "email": email
        ]
    }
}
