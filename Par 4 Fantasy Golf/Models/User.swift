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
    
//    // Helper function to fetch a user object from a user id
//    static func getUserFromId(id: String, completion: ((_ newUser: User) -> Void)? = nil) {
//
//        // Set user database reference
//        let userRef = Database.database().reference(withPath: "users/" + id)
//
//        userRef.observeSingleEvent(of: .value, with: { snapshot in
//
//            // Fetch user data
//            guard let user = User(snapshot: snapshot) else {
//                print("Error fetching user data")
//                return
//            }
//
//            if completion != nil {
//                completion!(user)
//            }
//
//        }) { error in
//          print(error.localizedDescription)
//        }
//    }
    
    // Helper function to fetch a user object from a user id
    static func getUserFromId(id: String) async -> User? {
            
        // Set user database reference
        let userRef = Database.database().reference(withPath: "users/" + id)
        
        // Attempt to create a user from a snapshot
        do {
            let snapshot = try await userRef.getData()
            if let user = User(snapshot: snapshot) {
                print("Created user from snapshot")
                return user
            } else {
                print("Couldn't create user from snapshot")
                return nil
            }
        } catch {
            print("Error fetching user data from firebase")
            return nil
        }
    }
}
