//
//  League.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 2/28/23.
//

// MARK: - Imported libraries

import FirebaseAuth
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
    var startDate: Double
    let creator: String
    var memberIds: [String]
    var members: [User]
    var athletes: [Athlete]
    var pickIds: [String: [String]]
    let budget: Int
    
    // MARK: - Initializers
    
    // Standard init
    init(name: String, startDate: Double, members: [User] = [], budget: Int) {
        uuid = UUID()
        databaseReference = Database.database().reference(withPath: "leagues/\(uuid)")
        self.name = name
        self.startDate = startDate
        
        // Set the current user as the creator when creating a new league
        if let user = Auth.auth().currentUser {
            creator = user.email!
        } else {
            creator = "unknown user"
        }
        
        self.memberIds = members.map { $0.id }
        self.members = members
        self.athletes = []
        self.pickIds = [:]
        self.budget = budget
    }
    
    // Init with snapshot data
    init?(snapshot: DataSnapshot) {
        
        // Validate the incoming values
        guard let value = snapshot.value as? [String: AnyObject],
              let id = UUID(uuidString: snapshot.key),
              let name = value["name"] as? String,
              let startDate = value["startDate"] as? Double,
              let creator = value["creator"] as? String,
            let budget = value["budget"] as? Int else { return nil }
        
        // Assign properties that will always have values
        uuid = id
        databaseReference = Database.database().reference(withPath: "leagues/\(uuid.uuidString)")
        self.name = name
        self.startDate = startDate
        self.creator = creator
        self.members = []
        self.pickIds = [:]
        self.budget = budget
        
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
        }
        
        if let pickIds = value["pickIds"] as? [String: [String: Bool]] {
            self.pickIds = pickIds.reduce(into: [String: [String]]()) {
                $0[$1.key] = $1.value.map { $0.key }
            }
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
            "creator": creator,
            "memberIds": memberDict,
            "athletes": athleteDict,
            "pickIds": pickDict,
            "budget": budget
        ]
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
            return leagues.sorted { $0.startDate > $1.startDate }
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
