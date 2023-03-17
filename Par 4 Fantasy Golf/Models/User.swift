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
            "email": email
        ]
    }
    
    // Helper function to fetch a user object from a user id
    static func fetchSingleUser(from id: String) async -> User? {
            
        // Set user database reference
        let userRef = Database.database().reference(withPath: "users/" + id)
        
        // Attempt to create a user from a snapshot
        do {
            let snapshot = try await userRef.getData()
            if let user = User(snapshot: snapshot) {
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
    
    // Helper function to fetch multiple user objects from an array of user ids
    static func fetchMultipleUsers(from ids: [String]) async -> [User] {
        
        // Use a task group to make sure that all user fetch requests return a response before we return the user array to the caller
        return await withTaskGroup(of: User?.self, returning: [User].self) { group in
            
            var users = [User]()
            
            // Loop through user IDs
            for id in ids {
                
                // Add a group task for each ID
                group.addTask {
                    
                    // Fetch user from ID
                    await User.fetchSingleUser(from: id)
                }
                
                // Wait for each user request to receive a response
                for await user in group {
                    
                    // Check each user that was generated. If it's not nil, append it
                    if let user = user {
                        users.append(user)
                    }
                }
            }
            
            // Return the users sorted in ascending order
            return users.sorted { $0.email < $1.email }
        }
    }
}
