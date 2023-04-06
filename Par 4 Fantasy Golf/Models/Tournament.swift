//
//  Tournament.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 4/4/23.
//

// MARK: - Imported libraries

import FirebaseAuth
import FirebaseDatabase

// MARK: - Main struct

// This model represents a tournament
struct Tournament: Hashable {
    
    // MARK: - Properties
    
    let uuid: UUID
    var id: String {
        uuid.uuidString
    }
    let databaseReference: DatabaseReference
    var name: String
    var startDate: String
    var endDate: String
    let creator: String
    var memberIds: [String]
    var members = [User]()
    var athletes = [Athlete]()
    var pickIds = [String: [String]]()
    let budget: Int
    var tournamentHasStarted = false
    var isUsingApi = false
    
    // MARK: - Initializers
    
    // Standard init
    init(name: String, startDate: String, endDate: String, members: [User] = [], budget: Int, isUsingApi: Bool = false) {
        uuid = UUID()
        databaseReference = Database.database().reference(withPath: "tournaments/\(uuid)")
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        
        // Set the current user as the creator when creating a new tournament
        if let user = Auth.auth().currentUser {
            creator = user.email!
        } else {
            creator = "unknown user"
        }
        
        self.memberIds = members.map { $0.id }
        self.members = members
        self.budget = budget
        self.isUsingApi = isUsingApi
    }
    
    // Init with snapshot data
    init?(snapshot: DataSnapshot) {
        
        // Validate the incoming values
        guard let value = snapshot.value as? [String: AnyObject],
              let id = UUID(uuidString: snapshot.key),
              let name = value["name"] as? String,
              let startDate = value["startDate"] as? String,
              let endDate = value["endDate"] as? String,
              let creator = value["creator"] as? String,
              let budget = value["budget"] as? Int,
              let tournamentHasStarted = value["tournamentHasStarted"] as? Bool,
              let isUsingApi = value["isUsingApi"] as? Bool else { return nil }
        
        // Assign properties that will always have values
        uuid = id
        databaseReference = Database.database().reference(withPath: "tournaments/\(uuid.uuidString)")
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.creator = creator
        self.budget = budget
        self.tournamentHasStarted = tournamentHasStarted
        self.isUsingApi = isUsingApi
        
        // Conditionally assign properties that may or may not have values
        if let memberIds = value["memberIds"] as? [String: Bool] {
            self.memberIds = memberIds.map { $0.key }
        } else {
            self.memberIds = []
        }
        
        self.athletes = []
        if let athletes = value["athletes"] as? [String: [String: AnyObject]] {
            for athlete in athletes {
                if let athleteFromSnapshot = Athlete(snapshot: snapshot.childSnapshot(forPath: "athletes/\(athlete.key)")) {
                    self.athletes.append(athleteFromSnapshot)
                } else {
                    print("Couldn't init athlete from snapshot")
                }
            }

            // Sort athletes
            self.athletes = self.athletes.sorted(by: { $0.name < $1.name })
        }

        if let pickIds = value["pickIds"] as? [String: [String: Bool]] {
            self.pickIds = pickIds.reduce(into: [String: [String]]()) {
                $0[$1.key] = $1.value.map { $0.key }
            }
        }
    }
    
    // MARK: - Functions
    
    // TODO: See if we can get this to work
//    // Populate tournament members with User objects constructed from tournament memberIds
//    mutating func populateMembers() async {
//        members = await User.fetchMultipleUsers(from: memberIds)
//    }
    
    // Convert the tournament to a Dictionary to be stored in Firebase
    func toAnyObject() -> Any {
        
        // Convert mebmerIds array to Firebase-style dictionary
        var memberDict = [String: Bool]()
        for member in members {
            memberDict[member.id] = true
        }
        
        // Convert athletes array to Firebase-style dictionary
        var athleteDict = [String: Any]()
        for athlete in athletes {
            athleteDict[athlete.id] = athlete.toAnyObject()
        }

        // Convert picks dictionary to Firebase-style dictionary
        var pickDict = [String: [String: Bool]]()
        for member in pickIds {
            var memberPicks = [String: Bool]()
            for pick in member.value {
                memberPicks[pick] = true
            }
            pickDict[member.key] = memberPicks
        }
        
        return [
            "name": name,
            "startDate": startDate,
            "endDate": endDate,
            "creator": creator,
            "memberIds": memberDict,
            "athletes": athleteDict,
            "pickIds": pickDict,
            "budget": budget,
            "tournamentHasStarted": tournamentHasStarted,
            "isUsingApi": isUsingApi
        ]
    }
    
    // Helper function to fetch a tournament object from a tournament id
    static func fetchSingleTournament(from id: String) async -> Tournament? {
            
        // Set tournament database reference
        let tournamentRef = Database.database().reference(withPath: "tournaments/" + id)
        
        // Attempt to create a tournament from a snapshot
        do {
            let snapshot = try await tournamentRef.getData()
            if let tournament = Tournament(snapshot: snapshot) {
                return tournament
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
    static func fetchMultipleTournaments(from ids: [String]) async -> [Tournament] {
        
        // Use a task group to make sure that all tournament fetch requests return a response before we return the tournament array to the caller
        return await withTaskGroup(of: Tournament?.self, returning: [Tournament].self) { group in
            
            var tournaments = [Tournament]()
            
            // Loop through tournament IDs
            for id in ids {
                
                // Add a group task for each ID
                group.addTask {
                    
                    // Fetch tournament from ID
                    await Tournament.fetchSingleTournament(from: id)
                }
                
                // Wait for each tournament request to receive a response
                for await tournament in group {
                    
                    // Check each tournament that was generated. If it's not nil, append it
                    if let tournament = tournament {
                        tournaments.append(tournament)
                    }
                }
            }
            
            // Return the tournaments sorted in descending order
            return tournaments.sorted { $0.startDate > $1.startDate }
        }
    }
}

// MARK: - Extensions

// This extension houses a date formatting helper function
extension Double {
    func formattedDate() -> String {
        return Date(timeIntervalSince1970: self).formatted(date: .numeric, time: .omitted)
    }
}