//
//  ObjectFetcher.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/30/23.
//

// This file contains test implementations for generic protocols/functions for the fetchSingle/fetchMultiple model functions
// This works by calling via ClassType.fetch____; need to update to work with calling ObjectFetcher.fetch____

import FirebaseDatabase

protocol InitializableFromSnapshot {
    init?(snapshot: DataSnapshot)
}

protocol CanFetch {
    associatedtype T: InitializableFromSnapshot = Self
    static func fetchSingleObject(from id: String, type: ObjectType) async -> T?
    static func fetchMultipleObjects(from ids: [String], type: ObjectType) async -> [T]
}

enum ObjectType: String {
    case league = "leagues"
    case minimalLeague = "leagueIds"
    case user = "users"
    //case athlete = Athlete
    
    init?(type: Any) {
        switch type.self {
        case is League.Type:
            self = .league
        case is MinimalLeague.Type:
            self = .minimalLeague
        case is User.Type:
            self = .user
        default:
            return nil
        }
    }
}

extension CanFetch {
    
    // Helper function to fetch an object from a league id
    static func fetchSingleObject(from id: String) async -> T? {
        //let leagueRef = Database.database().reference(withPath: "leagues/" + id)
        //let minimalLeagueRef = Database.database().reference(withPath: "leagueIds/" + id)
        //let userRef = Database.database().reference(withPath: "users/" + id)
        //let athleteRef = Database.database().reference(withPath: "leagues/" + leagueId + "/athletes/" + id)
        
        guard let objectString = ObjectType.init(type: Self.self) else { return nil }
        
        let typeRef = Database.database().reference(withPath: "\(objectString)/" + id)
        
        // Attempt to create an object from a snapshot
        do {
            let snapshot = try await typeRef.getData()
            if let object = T.init(snapshot: snapshot) {
                return object
            } else {
                print("Couldn't create object from snapshot")
                return nil
            }
        } catch {
            print("Error fetching league data from firebase")
            return nil
        }
    }
    
    // Helper function to fetch multiple objects from an array of object ids
    static func fetchMultipleObjects(from ids: [String]) async -> [T] {

        // Use a task group to make sure that all object fetch requests return a response before we return the object array to the caller
        return await withTaskGroup(of: T?.self, returning: [T].self) { group in

            var objects = [T]()

            // Loop through object IDs
            for id in ids {

                // Add a group task for each ID
                group.addTask {

                    // Fetch object from ID
                    await fetchSingleObject(from: id)
                }

                // Wait for each object request to receive a response
                for await object in group {

                    // Check each object that was generated. If it's not nil, append it
                    if let object = object {
                        objects.append(object)
                    }
                }
            }

            // Return the objects
            return objects
        }
    }
}
