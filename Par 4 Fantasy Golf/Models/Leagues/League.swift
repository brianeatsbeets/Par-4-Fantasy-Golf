//
//  League.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 2/28/23.
//

// TODO: Create utility functions for adding/removing/updating members, athletes, etc. to clean up code in view controllers

// MARK: - Imported libraries

import FirebaseDatabase

// MARK: - Main struct

// This model represents a league
struct League: Hashable {
    
    // MARK: - Properties
    
    let uuid: UUID
    var id: String {
        uuid.uuidString
    }
    let databaseReference: DatabaseReference
    var name: String
    let creator: String
    var memberIds: [String]
    var members = [User]()
    var tournamentIds: [String]
    var tournaments = [Tournament]()
    
    // MARK: - Initializers
    
    // Standard init
    init(name: String, creator: String) {
        uuid = UUID()
        databaseReference = Database.database().reference(withPath: "leagues/\(uuid)")
        self.name = name
        self.creator = creator
        self.memberIds = [creator]
        self.tournamentIds = []
    }
    
    // Init with snapshot data
    init?(snapshot: DataSnapshot) {
        
        // Validate the incoming values
        guard let value = snapshot.value as? [String: AnyObject],
              let id = UUID(uuidString: snapshot.key),
              let name = value["name"] as? String,
              let creator = value["creator"] as? String else { return nil }
        
        // Assign properties that will always have values
        uuid = id
        databaseReference = Database.database().reference(withPath: "leagues/\(uuid.uuidString)")
        self.name = name
        self.creator = creator
        
        // Conditionally assign properties that may or may not have values
        if let memberIds = value["memberIds"] as? [String: Bool] {
            self.memberIds = memberIds.map { $0.key }
        } else {
            self.memberIds = []
        }
        
        if let tournamentIds = value["tournamentIds"] as? [String: Bool] {
            self.tournamentIds = tournamentIds.map { $0.key }
        } else {
            self.tournamentIds = []
        }
    }
    
    // MARK: - Functions
    
    // TODO: See if we can get this to work
//    // Populate league members with User objects constructed from league memberIds
//    mutating func populateMembers() async {
//        members = await User.fetchMultipleUsers(from: memberIds)
//    }
    
    // Convert the league to a Dictionary to be stored in Firebase
    func toAnyObject() -> Any {
        
        // Convert mebmerIds array to Firebase-style dictionary
        var memberDict = [String: Bool]()
        for id in memberIds {
            memberDict[id] = true
        }
        
        // Convert tournamentIds array to Firebase-style dictionary
        var tourneyDict = [String: Bool]()
        for id in tournamentIds {
            tourneyDict[id] = true
        }
        
        return [
            "name": name,
            "creator": creator,
            "memberIds": memberDict,
            "tournamenIds": tourneyDict
        ] as [String : Any]
    }
    
    // Calculate the overall league standings
    func calculateLeagueStandings() -> [String: Int] {
        
        // Create a dictionary pre-filled with the league members' emails and a value of 0
        var standings: [String: Int] = {
            var dict = [String: Int]()
            for member in members {
                dict[member.email] = 0
            }
            return dict
        }()
        
        // Fetch each tournament's winner and add 1 to that member's value
        for tournament in tournaments {
            
            // Make sure the tournament has ended
            guard tournament.status == .completed else { continue }
            
            // Continue the loop gracefully if we don't find a standalone tournament winner
            guard tournament.winner != nil else {
                print("No (standalone) winner found for \(name) - \(tournament.name)")
                continue
            }
            
            // Continue the loop gracefully if we don't find a standings entry for a given tournament winner
            guard standings[tournament.winner!] != nil else {
                print("No standings info found for \(name) - \(tournament.name)")
                continue
            }
            
            standings[tournament.winner!]! += 1
        }
        
        return standings
    }
    
    // Helper function to fetch a league object from a league id
    static func fetchSingleLeague(from id: String) async -> League? {
            
        // Set league database reference
        let leagueRef = Database.database().reference(withPath: "leagues/" + id)
        
        // Attempt to create a league from a snapshot
        do {
            let snapshot = try await leagueRef.getData()
            if let league = League(snapshot: snapshot) {
                return league
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
    static func fetchMultipleLeagues(from ids: [String]) async -> [League] {
        
        // Use a task group to make sure that all league fetch requests return a response before we return the league array to the caller
        return await withTaskGroup(of: League?.self, returning: [League].self) { group in
            
            var leagues = [League]()
            
            // Loop through league IDs
            for id in ids {
                
                // Add a group task for each ID
                group.addTask {
                    
                    // Fetch league from ID
                    await League.fetchSingleLeague(from: id)
                }
                
                // Wait for each league request to receive a response
                for await league in group {
                    
                    // Check each league that was generated. If it's not nil, append it
                    if let league = league {
                        leagues.append(league)
                    }
                }
            }
            
            // Return the leagues sorted in descending order
            return leagues.sorted { $0.name > $1.name }
        }
    }
}
