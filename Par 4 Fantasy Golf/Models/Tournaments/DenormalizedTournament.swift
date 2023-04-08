//
//  DenormalizedTournament.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 4/7/23.
//

import FirebaseDatabase

// MARK: - Main struct

// This model represents a denormalized tournament
struct DenormalizedTournament: Hashable {
    
    // MARK: - Properties
    
    let id: String
    var name: String
    var startDate: Double
    var endDate: Double
    
    // MARK: - Initializers
    
    init(tournament: Tournament) {
        self.id = tournament.id
        self.name = tournament.name
        self.startDate = tournament.startDate
        self.endDate = tournament.endDate
    }
    
    // Init with snapshot data
    init?(snapshot: DataSnapshot) {
        
        // Validate and set the incoming values
        guard let value = snapshot.value as? [String: AnyObject],
              let name = value["name"] as? String,
              let startDate = value["startDate"] as? Double,
              let endDate = value["endDate"] as? Double else { return nil }

        self.id = snapshot.key
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
    }
    
    // MARK: - Functions
    
    // Convert the DenormalizedTournament to a Dictionary to be stored in Firebase
    func toAnyObject() -> Any {
        return [
            "name": name,
            "startDate": startDate,
            "endDate": endDate
        ]
    }
    
    // Helper function to fetch a tournament object from a tournament id
    static func fetchSingleTournament(from id: String) async -> DenormalizedTournament? {
        
        // Set tournament database reference
        let tournamentRef = Database.database().reference(withPath: "tournamentIds/" + id)
        
        // Attempt to create a tournament from a snapshot
        do {
            let snapshot = try await tournamentRef.getData()
            if let denormalizedTournament = DenormalizedTournament(snapshot: snapshot) {
                return denormalizedTournament
            } else {
                print("Couldn't create tournament from snapshot")
                return nil
            }
        } catch {
            print("Error fetching tournament data from firebase")
            return nil
        }
    }
    
    // Helper function to fetch multiple tournament objects from an array of tournament ids
    static func fetchMultipleTournaments(from ids: [String]) async -> [DenormalizedTournament] {
        
        // Use a task group to make sure that all tournament fetch requests return a response before we return the tournament array to the caller
        return await withTaskGroup(of: DenormalizedTournament?.self, returning: [DenormalizedTournament].self) { group in
            
            var denormalizedTournaments = [DenormalizedTournament]()
            
            // Loop through tournament IDs
            for id in ids {
                
                // Add a group task for each ID
                group.addTask {
                    
                    // Fetch tournament from ID
                    await DenormalizedTournament.fetchSingleTournament(from: id)
                }
                
                // Wait for each tournament request to receive a response
                for await denormalizedTournament in group {
                    
                    // Check each tournament that was generated. If it's not nil, append it
                    if let denormalizedTournament = denormalizedTournament {
                        denormalizedTournaments.append(denormalizedTournament)
                    }
                }
            }
            
            // Return the tournaments sorted in descending order
            return denormalizedTournaments.sorted { $0.name > $1.name }
        }
    }
}
