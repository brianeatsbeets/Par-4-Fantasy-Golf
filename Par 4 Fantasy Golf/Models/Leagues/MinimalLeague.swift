//
//  MinimalLeague.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 3/27/23.
//

import FirebaseDatabase

// MARK: - Main struct

// This model represents a minimal league
struct MinimalLeague: Hashable {
    
    // MARK: - Properties
    
    let id: String
    var name: String
    
    // MARK: - Initializers
    
    init(league: League) {
        self.id = league.id
        self.name = league.name
    }
    
    // Init with snapshot data
    init?(snapshot: DataSnapshot) {
        
        // Validate and set the incoming values
        guard let snapshotValue = snapshot.value as? [String: AnyObject],
              let name = snapshotValue["name"] as? String
              else { return nil }

        self.id = snapshot.key
        self.name = name
    }
    
    // MARK: - Functions
    
    // Convert the MinimalLeague to a Dictionary to be stored in Firebase
    func toAnyObject() -> Any {
        return [
            "name": name
        ]
    }
    
    // Helper function to fetch a league object from a league id
    static func fetchSingleLeague(from id: String) async -> MinimalLeague? {
        
        // Set league database reference
        let leagueRef = Database.database().reference(withPath: "leagueIds/" + id)
        
        // Attempt to create a league from a snapshot
        do {
            let snapshot = try await leagueRef.getData()
            if let minimalLeague = MinimalLeague(snapshot: snapshot) {
                return minimalLeague
            } else {
                print("Couldn't create league from snapshot")
                return nil
            }
        } catch {
            print("Error fetching league data from firebase")
            return nil
        }
    }
    
    // Helper function to fetch multiple league objects from an array of league ids
    static func fetchMultipleLeagues(from ids: [String]) async -> [MinimalLeague] {
        
        // Use a task group to make sure that all league fetch requests return a response before we return the league array to the caller
        return await withTaskGroup(of: MinimalLeague?.self, returning: [MinimalLeague].self) { group in
            
            var minimalLeagues = [MinimalLeague]()
            
            // Loop through league IDs
            for id in ids {
                
                // Add a group task for each ID
                group.addTask {
                    
                    // Fetch league from ID
                    await MinimalLeague.fetchSingleLeague(from: id)
                }
                
                // Wait for each league request to receive a response
                for await minimalLeague in group {
                    
                    // Check each league that was generated. If it's not nil, append it
                    if let minimalLeague = minimalLeague {
                        minimalLeagues.append(minimalLeague)
                    }
                }
            }
            
            // Return the leagues sorted in descending order
            return minimalLeagues.sorted { $0.name > $1.name }
        }
    }
}
