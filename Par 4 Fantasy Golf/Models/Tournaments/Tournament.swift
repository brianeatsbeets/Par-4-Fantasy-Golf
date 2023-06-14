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
    var espnId: String
    let databaseReference: DatabaseReference
    var name: String
    var startDate: Double
    var endDate: Double
    let creator: String
    var athletes = [Athlete]()
    var pickIds = [String: [String]]()
    var budget: Int
    var lastUpdateTime: Double
    var winner: String?
    
    // MARK: - Initializers
    
    // Standard init
    init(name: String, startDate: Double, endDate: Double, budget: Int, athletes: [Athlete], espnId: String) {
        uuid = UUID()
        databaseReference = Database.database().reference(withPath: "tournaments/\(uuid)")
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.budget = budget
        self.athletes = athletes
        self.espnId = espnId
        lastUpdateTime = Date.now.timeIntervalSince1970
        
        // Set the current user as the creator when creating a new tournament
        if let user = Auth.auth().currentUser {
            creator = user.email!
        } else {
            creator = "unknown user"
        }
    }
    
    // Init with snapshot data
    init?(snapshot: DataSnapshot) {
        
        // Validate the incoming values
        guard let value = snapshot.value as? [String: AnyObject],
              let id = UUID(uuidString: snapshot.key),
              let name = value["name"] as? String,
              let startDate = value["startDate"] as? Double,
              let endDate = value["endDate"] as? Double,
              let creator = value["creator"] as? String,
              let budget = value["budget"] as? Int,
              let espnId = value["espnId"] as? String,
              let lastUpdateTime = value["lastUpdateTime"] as? Double else { return nil }
        
        // Assign properties that will always have values
        uuid = id
        databaseReference = Database.database().reference(withPath: "tournaments/\(uuid.uuidString)")
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.creator = creator
        self.budget = budget
        self.espnId = espnId
        self.lastUpdateTime = lastUpdateTime
        
        // Assign properties that may or may not have values
        
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
        
        if let winner = value["winner"] as? String {
            self.winner = winner
        }
    }
    
    // MARK: - Functions
    
    // Calculate the tournament standings
    func calculateStandings(league: League) -> [TournamentStanding] {
        
        var newStandings = [TournamentStanding]()
        
        // Create a tournament standing object for each user
        for user in league.members {
            
            var topAthletes = [Athlete]()
            var cutAthleteCount = 0
            
            // If user has picked at least one athlete, calculate the top athletes
            if let userPicks = pickIds[user.id] {
                
                // Fetch the picked athletes
                var athletes = athletes.filter { userPicks.contains([$0.id]) }
                
                // Filter out and count cut athletes
                cutAthleteCount = athletes.filter { $0.isCut }.count
                athletes = athletes.filter { !$0.isCut }
                
                // Sort and copy the top athletes to a new array
                if !athletes.isEmpty {
                    let sortedAthletes = athletes.sorted { $0.score < $1.score }
                    let athleteCount = sortedAthletes.count >= 4 ? 3 : sortedAthletes.count - 1
                    topAthletes = Array(sortedAthletes[0...athleteCount])
                }
            }
            
            // Create and append a new tournament standing to the temporary container
            let userStanding = TournamentStanding(tournamentId: id, user: user, topAthletes: topAthletes, penalties: cutAthleteCount)
            newStandings.append(userStanding)
        }
        
        // Sort the standings
        newStandings = newStandings.sorted(by: <)
        
        //  Format and assign placements
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        newStandings.indices.forEach { newStandings[$0].place = formatter.string(for: $0+1)! }
        
        // Account for ties
        var i = 0
        while i < newStandings.count-1 {
            if newStandings[i].score == newStandings[i+1].score {
                
                // Don't add a 'T' if the place already has one
                if !newStandings[i].place.hasPrefix("T") {
                    newStandings[i].place = "T" + newStandings[i].place
                }
                newStandings[i+1].place = newStandings[i].place
            }
            i += 1
        }
        
        // Return the standings
        return newStandings
    }
    
    // Convert the tournament to a Dictionary to be stored in Firebase
    func toAnyObject() -> Any {
        
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
            "athletes": athleteDict,
            "pickIds": pickDict,
            "budget": budget,
            "espnId": espnId,
            "lastUpdateTime": lastUpdateTime
        ] as [String : Any]
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
    
    // Fetch updated athlete data
    static func fetchEventAthleteData(eventId: String) async throws -> [Athlete] {
        
        print("Fetching athlete data from ESPN api")
        
        var athletes = [Athlete]()
        let data: Data
        let response: URLResponse
        
        // Construct URL
        let url = URL(string: "https://site.api.espn.com/apis/site/v2/sports/golf/leaderboard?event=\(eventId)")!
        
        do {
            // Request data from the URL
            (data, response) = try await URLSession.shared.data(from: url)
        } catch {
            print("Caught error from URLSession.shared.data function")
            throw EventAthleteDataError.dataTaskError
        }
            
        // Make sure we have a valid HTTP response
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else { throw EventAthleteDataError.invalidHttpResponse }
        
        // Make sure we can decode the data
        guard let apiResponse = try? JSONDecoder().decode(EventApiResponse.self, from: data) else { throw EventAthleteDataError.decodingError }
            
        // Get the competitors
        let competitors = apiResponse.events[0].competitions[0].competitors
        
        // If there are no competitors, exit early
        if competitors.isEmpty {
            print("No competitors found")
            throw EventAthleteDataError.noCompetitorData
        }
        
        // Parse each competitor and create an Athlete from each one
        for competitor in competitors {
            let scoreString = competitor.score.displayValue
            let id = competitor.id
            var isCut = false
            var score = 0
            
            // Convert score string to int
            if scoreString != "E",
               Int(scoreString) != nil {
                score = Int(scoreString)!
            }
            
            let name = competitor.athlete.displayName
            if competitor.status.displayValue == "CUT" {
                isCut = true
            }
            
            athletes.append(Athlete(espnId: id, name: name, score: score, isCut: isCut))
        }
        
        // Sort the athletes
        athletes = athletes.sorted { $0.name < $1.name }
        
        return athletes
    }
}

// MARK: - Extensions

// This extension houses a date formatting helper function
extension Double {
    func formattedDate() -> String {
        return Date(timeIntervalSince1970: self).formatted(date: .numeric, time: .omitted)
    }
}

// This extension converts the ESPN date string into more usable formats
extension String {
    
    // Return a since-epoch double
    func espnDateStringToDouble() -> Double? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        guard let date = formatter.date(from: self) else {
            print("Couldn't convert ESPN date string to date")
            return nil
        }
        return date.timeIntervalSince1970
    }
}

// MARK: - Extensions

// This enum provides error cases for fetching event athlete data
enum EventAthleteDataError: Error {
    case dataTaskError
    case invalidHttpResponse
    case decodingError
    case noCompetitorData
}
