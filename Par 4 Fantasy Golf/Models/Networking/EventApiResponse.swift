//
//  EventApiResponse.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 4/11/23.
//

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let welcome = try? JSONDecoder().decode(EventApiResponse.self, from: jsonData)

import Foundation

// MARK: - EventApiResponse
struct EventApiResponse: Codable {
    let events: [Event]

    enum CodingKeys: String, CodingKey {
        case events = "events"
    }
}

// MARK: - Event
struct Event: Codable {
    let id: String
    //let uid: String
    let date: String
    let endDate: String
    let name: String
    //let shortName: String
    //let season: Season
    let competitions: [Competition]
    //let links: [Link]
    //let league: League
    //let defendingChampion: DefendingChampion
    //let tournament: Tournament
    let status: EventStatus
    //let purse: Int
    //let displayPurse: String
    //let playoffType: PlayoffType
    //let courses: [Course]
    //let primary: Bool
    //let hasPlayerStats: Bool
    //let hasCourseStats: Bool
    //let airings: [JSONAny]
    //let athleteAirings: [JSONAny]

    enum CodingKeys: String, CodingKey {
        case id = "id"
        //case uid = "uid"
        case date = "date"
        case endDate = "endDate"
        case name = "name"
        //case shortName = "shortName"
        //case season = "season"
        case competitions = "competitions"
        //case links = "links"
        //case league = "league"
        //case defendingChampion = "defendingChampion"
        //case tournament = "tournament"
        case status = "status"
        //case purse = "purse"
        //case displayPurse = "displayPurse"
        //case playoffType = "playoffType"
        //case courses = "courses"
        //case primary = "primary"
        //case hasPlayerStats = "hasPlayerStats"
        //case hasCourseStats = "hasCourseStats"
        //case airings = "airings"
        //case athleteAirings = "athleteAirings"
    }
}

// MARK: - Competition
struct Competition: Codable {
    //let id: String
    //let uid: String
    //let date: String
    //let endDate: String
    //let scoringSystem: ScoringSystem
    //let onWatchESPN: Bool
    //let recent: Bool
    let competitors: [Competitor]
    //let status: CompetitionStatus
    //let broadcasts: [Broadcast]
    //let dataFormat: String
    //let holeByHoleSource: HoleByHoleSource

    enum CodingKeys: String, CodingKey {
        //case id = "id"
        //case uid = "uid"
        //case date = "date"
        //case endDate = "endDate"
        //case scoringSystem = "scoringSystem"
        //case onWatchESPN = "onWatchESPN"
        //case recent = "recent"
        case competitors = "competitors"
        //case status = "status"
        //case broadcasts = "broadcasts"
        //case dataFormat = "dataFormat"
        //case holeByHoleSource = "holeByHoleSource"
    }
}

//// MARK: - Broadcast
//struct Broadcast: Codable {
//    let media: Media
//    let lang: String
//    let region: String
//
//    enum CodingKeys: String, CodingKey {
//        case media = "media"
//        case lang = "lang"
//        case region = "region"
//    }
//}

//// MARK: - Media
//struct Media: Codable {
//    let ref: String
//    let id: String
//    let callLetters: String
//    let name: String
//    let shortName: String
//    let slug: String
//
//    enum CodingKeys: String, CodingKey {
//        case ref = "$ref"
//        case id = "id"
//        case callLetters = "callLetters"
//        case name = "name"
//        case shortName = "shortName"
//        case slug = "slug"
//    }
//}

// MARK: - Competitor
struct Competitor: Codable {
    let id: String
    //let uid: String
    let athlete: CompetitorAthlete
    let status: CompetitorStatus
    let score: Score
    //let linescores: [Linescore] // Maybe need these?
    //let earnings: Int
    //let amateur: Bool
    //let statistics: [JSONAny]
    //let featured: Bool
    //let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id = "id"
        //case uid = "uid"
        case athlete = "athlete"
        case status = "status"
        case score = "score"
        //case linescores = "linescores"
        //case earnings = "earnings"
        //case amateur = "amateur"
        //case statistics = "statistics"
        //case featured = "featured"
        //case sortOrder = "sortOrder"
    }
}

// MARK: - CompetitorAthlete
struct CompetitorAthlete: Codable {
    //let id: String
    //let uid: String
    //let guid: String
    //let lastName: String
    let displayName: String
    //let amateur: Bool
    //let links: [Link]
    //let birthPlace: BirthPlace?
    //let headshot: Headshot?
    //let flag: Flag

    enum CodingKeys: String, CodingKey {
        //case id = "id"
        //case uid = "uid"
        //case guid = "guid"
        //case lastName = "lastName"
        case displayName = "displayName"
        //case amateur = "amateur"
        //case links = "links"
        //case birthPlace = "birthPlace"
        //case headshot = "headshot"
        //case flag = "flag"
    }
}

//// MARK: - BirthPlace
//struct BirthPlace: Codable {
//    let stateAbbreviation: String?
//    let countryAbbreviation: String
//
//    enum CodingKeys: String, CodingKey {
//        case stateAbbreviation = "stateAbbreviation"
//        case countryAbbreviation = "countryAbbreviation"
//    }
//}

//// MARK: - Flag
//struct Flag: Codable {
//    let href: String
//    let alt: String
//
//    enum CodingKeys: String, CodingKey {
//        case href = "href"
//        case alt = "alt"
//    }
//}

//// MARK: - Headshot
//struct Headshot: Codable {
//    let href: String
//
//    enum CodingKeys: String, CodingKey {
//        case href = "href"
//    }
//}

//// MARK: - Link
//struct Link: Codable {
//    let language: Language
//    let rel: [String]
//    let href: String
//    let text: Text
//    let shortText: Text
//    let isExternal: Bool
//    let isPremium: Bool
//
//    enum CodingKeys: String, CodingKey {
//        case language = "language"
//        case rel = "rel"
//        case href = "href"
//        case text = "text"
//        case shortText = "shortText"
//        case isExternal = "isExternal"
//        case isPremium = "isPremium"
//    }
//}

//enum Language: String, Codable {
//    case enUS = "en-US"
//}

//enum Text: String, Codable {
//    case bio = "Bio"
//    case leaderboard = "Leaderboard"
//    case news = "News"
//    case overview = "Overview"
//    case playerCard = "Player Card"
//    case results = "Results"
//    case scorecards = "Scorecards"
//    case summary = "Summary"
//    case weather = "Weather"
//}

//// MARK: - Linescore
//struct Linescore: Codable {
//    let period: Int
//    let hasStream: Bool
//    let teeTime: String
//
//    enum CodingKeys: String, CodingKey {
//        case period = "period"
//        case hasStream = "hasStream"
//        case teeTime = "teeTime"
//    }
//}

// MARK: - Score
struct Score: Codable {
    let displayValue: String
    //let value: Int

    enum CodingKeys: String, CodingKey {
        case displayValue = "displayValue"
        //case value = "value"
    }
}

//enum WindDirection: String, Codable {
//    case e = "E"
//}

// MARK: - CompetitorStatus
struct CompetitorStatus: Codable {
    //let period: Int
    //let type: PurpleType
    let displayValue: String?
    //let teeTime: String
    //let startHole: Int
    //let position: Position
    //let thru: Int
    //let playoff: Bool
    //let behindCurrentRound: Bool

    enum CodingKeys: String, CodingKey {
        //case period = "period"
        //case type = "type"
        case displayValue = "displayValue"
        //case teeTime = "teeTime"
        //case startHole = "startHole"
        //case position = "position"
        //case thru = "thru"
        //case playoff = "playoff"
        //case behindCurrentRound = "behindCurrentRound"
    }
}

//// MARK: - Position
//struct Position: Codable {
//    let id: String
//    let displayName: DisplayName
//    let isTie: Bool
//
//    enum CodingKeys: String, CodingKey {
//        case id = "id"
//        case displayName = "displayName"
//        case isTie = "isTie"
//    }
//}

//enum DisplayName: String, Codable {
//    case empty = "-"
//}

//// MARK: - PurpleType
//struct PurpleType: Codable {
//    let id: String
//    let name: Name
//    let state: State
//    let completed: Bool?
//    let description: Description
//    let detail: Description
//    let shortDetail: ShortDetail
//
//    enum CodingKeys: String, CodingKey {
//        case id = "id"
//        case name = "name"
//        case state = "state"
//        case completed = "completed"
//        case description = "description"
//        case detail = "detail"
//        case shortDetail = "shortDetail"
//    }
//}
//
//enum Description: String, Codable {
//    case scheduled = "Scheduled"
//    case thuApril12ThAt1200AMEDT = "Thu, April 12th at 12:00 AM EDT"
//}
//
//enum Name: String, Codable {
//    case statusScheduled = "STATUS_SCHEDULED"
//}
//
//enum ShortDetail: String, Codable {
//    case scheduled = "Scheduled"
//    case the4131200AmEdt = "4/13 - 12:00 AM EDT"
//}
//
//enum State: String, Codable {
//    case pre = "pre"
//}
//
//// MARK: - HoleByHoleSource
//struct HoleByHoleSource: Codable {
//    let id: String
//    let description: String
//    let state: String
//
//    enum CodingKeys: String, CodingKey {
//        case id = "id"
//        case description = "description"
//        case state = "state"
//    }
//}

//// MARK: - ScoringSystem
//struct ScoringSystem: Codable {
//    let id: String
//    let name: String
//
//    enum CodingKeys: String, CodingKey {
//        case id = "id"
//        case name = "name"
//    }
//}
//
//// MARK: - CompetitionStatus
//struct CompetitionStatus: Codable {
//    let period: Int
//    let type: PurpleType
//
//    enum CodingKeys: String, CodingKey {
//        case period = "period"
//        case type = "type"
//    }
//}
//
//// MARK: - Course
//struct Course: Codable {
//    let id: String
//    let name: String
//    let address: Address
//    let weather: Weather
//    let totalYards: Int
//    let shotsToPar: Int
//    let parIn: Int
//    let parOut: Int
//    let holes: [Hole]
//    let host: Bool
//
//    enum CodingKeys: String, CodingKey {
//        case id = "id"
//        case name = "name"
//        case address = "address"
//        case weather = "weather"
//        case totalYards = "totalYards"
//        case shotsToPar = "shotsToPar"
//        case parIn = "parIn"
//        case parOut = "parOut"
//        case holes = "holes"
//        case host = "host"
//    }
//}
//
//// MARK: - Address
//struct Address: Codable {
//    let city: String
//    let state: String
//    let zipCode: String
//    let country: String
//
//    enum CodingKeys: String, CodingKey {
//        case city = "city"
//        case state = "state"
//        case zipCode = "zipCode"
//        case country = "country"
//    }
//}
//
//// MARK: - Hole
//struct Hole: Codable {
//    let number: Int
//    let shotsToPar: Int
//    let totalYards: Int
//
//    enum CodingKeys: String, CodingKey {
//        case number = "number"
//        case shotsToPar = "shotsToPar"
//        case totalYards = "totalYards"
//    }
//}

//// MARK: - Weather
//struct Weather: Codable {
//    let type: String
//    let displayValue: String
//    let zipCode: String
//    let lastUpdated: String
//    let windSpeed: Int
//    let windDirection: WindDirection
//    let temperature: Int
//    let highTemperature: Int
//    let lowTemperature: Int
//    let conditionID: String
//    let gust: Int
//    let precipitation: Int
//    let link: Link
//
//    enum CodingKeys: String, CodingKey {
//        case type = "type"
//        case displayValue = "displayValue"
//        case zipCode = "zipCode"
//        case lastUpdated = "lastUpdated"
//        case windSpeed = "windSpeed"
//        case windDirection = "windDirection"
//        case temperature = "temperature"
//        case highTemperature = "highTemperature"
//        case lowTemperature = "lowTemperature"
//        case conditionID = "conditionId"
//        case gust = "gust"
//        case precipitation = "precipitation"
//        case link = "link"
//    }
//}
//
//// MARK: - DefendingChampion
//struct DefendingChampion: Codable {
//    let athlete: DefendingChampionAthlete
//
//    enum CodingKeys: String, CodingKey {
//        case athlete = "athlete"
//    }
//}
//
//// MARK: - DefendingChampionAthlete
//struct DefendingChampionAthlete: Codable {
//    let id: String
//    let displayName: String
//    let amateur: Bool
//
//    enum CodingKeys: String, CodingKey {
//        case id = "id"
//        case displayName = "displayName"
//        case amateur = "amateur"
//    }
//}
//
//// MARK: - League
//struct League: Codable {
//    let id: String
//    let name: String
//    let abbreviation: String
//    let shortName: String
//    let slug: String
//
//    enum CodingKeys: String, CodingKey {
//        case id = "id"
//        case name = "name"
//        case abbreviation = "abbreviation"
//        case shortName = "shortName"
//        case slug = "slug"
//    }
//}
//
//// MARK: - PlayoffType
//struct PlayoffType: Codable {
//    let id: Int
//    let description: String
//    let minimumHoles: Int
//
//    enum CodingKeys: String, CodingKey {
//        case id = "id"
//        case description = "description"
//        case minimumHoles = "minimumHoles"
//    }
//}
//
//// MARK: - Season
//struct Season: Codable {
//    let year: Int
//
//    enum CodingKeys: String, CodingKey {
//        case year = "year"
//    }
//}

// MARK: - EventStatus
struct EventStatus: Codable {
    let type: EventStatusType

    enum CodingKeys: String, CodingKey {
        case type = "type"
    }
}

// MARK: - EventStatusType
struct EventStatusType: Codable {
    let id: String
    //let name: Name
    //let state: State
    let completed: Bool
    let description: String

    enum CodingKeys: String, CodingKey {
        case id = "id"
        //case name = "name"
        //case state = "state"
        case completed = "completed"
        case description = "description"
    }
}

//// MARK: - Tournament
//struct Tournament: Codable {
//    let id: String
//    let displayName: String
//    let major: Bool
//    let scoringSystem: ScoringSystem
//    let numberOfRounds: Int
//    let cutRound: Int
//    let cutScore: Int
//    let cutCount: Int
//
//    enum CodingKeys: String, CodingKey {
//        case id = "id"
//        case displayName = "displayName"
//        case major = "major"
//        case scoringSystem = "scoringSystem"
//        case numberOfRounds = "numberOfRounds"
//        case cutRound = "cutRound"
//        case cutScore = "cutScore"
//        case cutCount = "cutCount"
//    }
//}

// MARK: - Encode/decode helpers

class JSONNull: Codable, Hashable {

    public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
        return true
    }

//    public var hashValue: Int {
//        return 0
//    }
    
    func hash(into hasher: inout Hasher) {}

    public init() {}

    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if !container.decodeNil() {
            throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

class JSONCodingKey: CodingKey {
    let key: String

    required init?(intValue: Int) {
        return nil
    }

    required init?(stringValue: String) {
        key = stringValue
    }

    var intValue: Int? {
        return nil
    }

    var stringValue: String {
        return key
    }
}

class JSONAny: Codable {

    let value: Any

    static func decodingError(forCodingPath codingPath: [CodingKey]) -> DecodingError {
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode JSONAny")
        return DecodingError.typeMismatch(JSONAny.self, context)
    }

    static func encodingError(forValue value: Any, codingPath: [CodingKey]) -> EncodingError {
        let context = EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode JSONAny")
        return EncodingError.invalidValue(value, context)
    }

    static func decode(from container: SingleValueDecodingContainer) throws -> Any {
        if let value = try? container.decode(Bool.self) {
            return value
        }
        if let value = try? container.decode(Int64.self) {
            return value
        }
        if let value = try? container.decode(Double.self) {
            return value
        }
        if let value = try? container.decode(String.self) {
            return value
        }
        if container.decodeNil() {
            return JSONNull()
        }
        throw decodingError(forCodingPath: container.codingPath)
    }

    static func decode(from container: inout UnkeyedDecodingContainer) throws -> Any {
        if let value = try? container.decode(Bool.self) {
            return value
        }
        if let value = try? container.decode(Int64.self) {
            return value
        }
        if let value = try? container.decode(Double.self) {
            return value
        }
        if let value = try? container.decode(String.self) {
            return value
        }
        if let value = try? container.decodeNil() {
            if value {
                return JSONNull()
            }
        }
        if var container = try? container.nestedUnkeyedContainer() {
            return try decodeArray(from: &container)
        }
        if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self) {
            return try decodeDictionary(from: &container)
        }
        throw decodingError(forCodingPath: container.codingPath)
    }

    static func decode(from container: inout KeyedDecodingContainer<JSONCodingKey>, forKey key: JSONCodingKey) throws -> Any {
        if let value = try? container.decode(Bool.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Int64.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Double.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(String.self, forKey: key) {
            return value
        }
        if let value = try? container.decodeNil(forKey: key) {
            if value {
                return JSONNull()
            }
        }
        if var container = try? container.nestedUnkeyedContainer(forKey: key) {
            return try decodeArray(from: &container)
        }
        if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key) {
            return try decodeDictionary(from: &container)
        }
        throw decodingError(forCodingPath: container.codingPath)
    }

    static func decodeArray(from container: inout UnkeyedDecodingContainer) throws -> [Any] {
        var arr: [Any] = []
        while !container.isAtEnd {
            let value = try decode(from: &container)
            arr.append(value)
        }
        return arr
    }

    static func decodeDictionary(from container: inout KeyedDecodingContainer<JSONCodingKey>) throws -> [String: Any] {
        var dict = [String: Any]()
        for key in container.allKeys {
            let value = try decode(from: &container, forKey: key)
            dict[key.stringValue] = value
        }
        return dict
    }

    static func encode(to container: inout UnkeyedEncodingContainer, array: [Any]) throws {
        for value in array {
            if let value = value as? Bool {
                try container.encode(value)
            } else if let value = value as? Int64 {
                try container.encode(value)
            } else if let value = value as? Double {
                try container.encode(value)
            } else if let value = value as? String {
                try container.encode(value)
            } else if value is JSONNull {
                try container.encodeNil()
            } else if let value = value as? [Any] {
                var container = container.nestedUnkeyedContainer()
                try encode(to: &container, array: value)
            } else if let value = value as? [String: Any] {
                var container = container.nestedContainer(keyedBy: JSONCodingKey.self)
                try encode(to: &container, dictionary: value)
            } else {
                throw encodingError(forValue: value, codingPath: container.codingPath)
            }
        }
    }

    static func encode(to container: inout KeyedEncodingContainer<JSONCodingKey>, dictionary: [String: Any]) throws {
        for (key, value) in dictionary {
            let key = JSONCodingKey(stringValue: key)!
            if let value = value as? Bool {
                try container.encode(value, forKey: key)
            } else if let value = value as? Int64 {
                try container.encode(value, forKey: key)
            } else if let value = value as? Double {
                try container.encode(value, forKey: key)
            } else if let value = value as? String {
                try container.encode(value, forKey: key)
            } else if value is JSONNull {
                try container.encodeNil(forKey: key)
            } else if let value = value as? [Any] {
                var container = container.nestedUnkeyedContainer(forKey: key)
                try encode(to: &container, array: value)
            } else if let value = value as? [String: Any] {
                var container = container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key)
                try encode(to: &container, dictionary: value)
            } else {
                throw encodingError(forValue: value, codingPath: container.codingPath)
            }
        }
    }

    static func encode(to container: inout SingleValueEncodingContainer, value: Any) throws {
        if let value = value as? Bool {
            try container.encode(value)
        } else if let value = value as? Int64 {
            try container.encode(value)
        } else if let value = value as? Double {
            try container.encode(value)
        } else if let value = value as? String {
            try container.encode(value)
        } else if value is JSONNull {
            try container.encodeNil()
        } else {
            throw encodingError(forValue: value, codingPath: container.codingPath)
        }
    }

    public required init(from decoder: Decoder) throws {
        if var arrayContainer = try? decoder.unkeyedContainer() {
            self.value = try JSONAny.decodeArray(from: &arrayContainer)
        } else if var container = try? decoder.container(keyedBy: JSONCodingKey.self) {
            self.value = try JSONAny.decodeDictionary(from: &container)
        } else {
            let container = try decoder.singleValueContainer()
            self.value = try JSONAny.decode(from: container)
        }
    }

    public func encode(to encoder: Encoder) throws {
        if let arr = self.value as? [Any] {
            var container = encoder.unkeyedContainer()
            try JSONAny.encode(to: &container, array: arr)
        } else if let dict = self.value as? [String: Any] {
            var container = encoder.container(keyedBy: JSONCodingKey.self)
            try JSONAny.encode(to: &container, dictionary: dict)
        } else {
            var container = encoder.singleValueContainer()
            try JSONAny.encode(to: &container, value: self.value)
        }
    }
}
