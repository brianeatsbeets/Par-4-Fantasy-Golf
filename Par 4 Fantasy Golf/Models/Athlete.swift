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
    
    let uuid: UUID
    var id: String {
        uuid.uuidString
    }
    var name: String
    var odds: Int
    var value: Int
    var score: Int
    var formattedScore: String {
        switch score {
        case 1...:
            return "+\(score)"
        case ..<0:
            return "\(score)"
        default:
            return "E"
        }
    }
    
    // MARK: - Initializers
    
    // Standard init
    init(id: UUID = UUID(), name: String, odds: Int, value: Int) {
        self.uuid = id
        self.name = name
        self.odds = odds
        self.value = value
        score = 0
    }
    
    // Init with snapshot data
    init?(snapshot: DataSnapshot) {
        print("Athlete created")
        // Validate and set the incoming values
        guard let snapshotValue = snapshot.value as? [String: AnyObject],
              let id = UUID(uuidString: snapshot.key),
              let name = snapshotValue["name"] as? String,
              let odds = snapshotValue["odds"] as? Int,
              let value = snapshotValue["value"] as? Int else { return nil }

        self.uuid = id
        self.name = name
        self.odds = odds
        self.value = value
        
        if let score = snapshotValue["score"] as? Int {
            self.score = score
        } else {
            self.score = 0
        }
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
    
    // Helper function to fetch a user object from a user id
    static func fetchSingleAthlete(from id: String, leagueId: String) async -> Athlete? {
            
        // Set athlete database reference
        let athleteRef = Database.database().reference(withPath: "leagues/" + leagueId + "/athletes/" + id)
        
        // Attempt to create a athlete from a snapshot
        do {
            let snapshot = try await athleteRef.getData() // getData() has a bug where it will return data from an observed DatabaseReference that is higher-level in the database hierarchy, if such an observer was created.
            if let athlete = Athlete(snapshot: snapshot) {
                return athlete
            } else {
                print("Couldn't create athlete from snapshot")
                return nil
            }
        } catch {
            print("Error fetching athlete data from firebase")
            return nil
        }
    }
    
    // Helper function to fetch multiple athlete objects from an array of athlete ids
    static func fetchMultipleAthletes(from ids: [String], leagueId: String) async -> [Athlete] {
        
        // Use a task group to make sure that all athlete fetch requests return a response before we return the athlete array to the caller
        return await withTaskGroup(of: Athlete?.self, returning: [Athlete].self) { group in
            
            var athletes = [Athlete]()
            
            // Loop through athlete IDs
            for id in ids {
                
                // Add a group task for each ID
                group.addTask {
                    
                    // Fetch athlete from ID
                    await Athlete.fetchSingleAthlete(from: id, leagueId: leagueId)
                }
                
                // Wait for each athlete request to receive a response
                for await athlete in group {
                    
                    // Check each athlete that was generated. If it's not nil, append it
                    if let athlete = athlete {
                        athletes.append(athlete)
                    }
                }
            }
            
            // Return the athletes // sorted in ascending order
            return athletes //.sorted { $0.email < $1.email }
        }
    }
}
