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
    //var startDate: Double
    
    // MARK: - Initializers
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
        //self.startDate = startDate
    }
    
    // Init with snapshot data
    init?(snapshot: DataSnapshot) {
        
        // Validate and set the incoming values
        guard let snapshotValue = snapshot.value as? [String: AnyObject],
              let name = snapshotValue["name"] as? String
              //let startDate = snapshotValue["startDate"] as? Double
              else { return nil }

        self.id = snapshot.key
        self.name = name
        //self.startDate = startDate
    }
    
    // MARK: - Functions
    
    // Convert the DenormalizedLeague to a Dictionary to be stored in Firebase
    func toAnyObject() -> Any {
        return [
            "name": name
            //"startDate": startDate
        ]
    }
    
    // Helper function to fetch a league object from a league id
    static func fetchSingleLeague(from id: String) async -> DenormalizedLeague? {
        
        // Set league database reference
        let leagueRef = Database.database().reference(withPath: "leagueIds/" + id)
        
        // Attempt to create a league from a snapshot
        do {
            let snapshot = try await leagueRef.getData()
            if let denormalizedLeague = DenormalizedLeague(snapshot: snapshot) {
                return denormalizedLeague
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
    static func fetchMultipleLeagues(from ids: [String]) async -> [DenormalizedLeague] {
        
        // Use a task group to make sure that all league fetch requests return a response before we return the league array to the caller
        return await withTaskGroup(of: DenormalizedLeague?.self, returning: [DenormalizedLeague].self) { group in
            
            var denormalizedLeagues = [DenormalizedLeague]()
            
            // Loop through league IDs
            for id in ids {
                
                // Add a group task for each ID
                group.addTask {
                    
                    // Fetch league from ID
                    await DenormalizedLeague.fetchSingleLeague(from: id)
                }
                
                // Wait for each league request to receive a response
                for await denormalizedLeague in group {
                    
                    // Check each league that was generated. If it's not nil, append it
                    if let denormalizedLeague = denormalizedLeague {
                        denormalizedLeagues.append(denormalizedLeague)
                    }
                }
            }
            
            // Return the leagues sorted in descending order
            return denormalizedLeagues.sorted { $0.name > $1.name }
        }
    }
}
