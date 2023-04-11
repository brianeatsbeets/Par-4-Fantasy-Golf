//
//  CalendarApiResponse.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 4/1/23.
//  Models created from ESPN JSON structure using https://app.quicktype.io/
//

// TODO: See if we can flatten these models to reduce the number and make the process more efficient

import Foundation

// MARK: - Top Level

// This is the top-level item in the JSON tree
struct CalendarApiResponse: Codable {
    let activeLeagues: [ProfessionalLeague] // Drill down for calendar
    //let activeEvents: [Event] // Drill down for competitors and event status

    enum CodingKeys: String, CodingKey {
        case activeLeagues = "leagues"
        //case activeEvents = "events"
    }
}

// MARK: - League Schedule

// This is a league that contains a league schedule
struct ProfessionalLeague: Codable {
    let id: String // League ID - may not be needed
    let name: String // League name (i.e. PGA TOUR)
    let calendarStartDate: String // League start date
    let calendarEndDate: String // League end date
    let calendar: [CalendarEvent] // Array of individual schedule events

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case calendarStartDate = "calendarStartDate"
        case calendarEndDate = "calendarEndDate"
        case calendar = "calendar"
    }
}

// This is an individual event on the schedule
struct CalendarEvent: Codable, Hashable, Equatable {
    let name: String // Event name
    let startDate: String // Event start date
    let endDate: String // Event end date
    var urlContainer: CalendarEventUrl // Contains url with event ID
    var eventId: String {
        if let id = URL(string: urlContainer.url)?.lastPathComponent {
            return id
        } else {
            print("Couldn't extract event ID from event URL")
            return "nil"
        }
    }

    enum CodingKeys: String, CodingKey {
        case name = "label"
        case startDate = "startDate"
        case endDate = "endDate"
        case urlContainer = "event"
    }
}

// This is a container for the event URL
// TODO: Extract event ID from URL - actually, do we need to do this? Depends on how we fetch/collect data for past tournaments
struct CalendarEventUrl: Codable, Hashable, Equatable {
    let url: String

    enum CodingKeys: String, CodingKey {
        case url = "$ref"
    }
}

// MARK: - Competition Data

//// This is an event that is/was active on the date provided to the API call
//struct Event: Codable {
//    let id: String // Event ID - may not be needed
//    let startDate: String // Event start date
//    let endDate: String // Event end date
//    let name: String // Event name
//    let competitions: [Competition] // Drill down for competitors
//
//    enum CodingKeys: String, CodingKey {
//        case id = "id"
//        case startDate = "date"
//        case endDate = "endDate"
//        case name = "name"
//        case competitions = "competitions"
//    }
//}
//
//// This is a container for event status and competitor data
//struct Competition: Codable {
//    let competitors: [Competitor]? // Drill down for competitor data
//    let status: CompetitionStatus // Drill down for competition status
//
//    enum CodingKeys: String, CodingKey {
//        case competitors = "competitors"
//        case status = "status"
//    }
//}
//
//// This is a container for the competition status
//struct CompetitionStatus: Codable {
//    let statusDetails: CompetitionStatusDetail // Contains competition status details
//
//    enum CodingKeys: String, CodingKey {
//        case statusDetails = "type"
//    }
//}
//
//// This is a container for the competition status details
//struct CompetitionStatusDetail: Codable {
//    let isCompleted: Bool // Whether or not the event has completed
//    let statusDescription: String // Textual description of event status (i.e. "Round 2 - In Progress")
//
//    enum CodingKeys: String, CodingKey {
//        case isCompleted = "completed"
//        case statusDescription = "description"
//    }
//}
//
//// MARK: - Competitor Data
//
//// This is an individual competitor for this event
//struct Competitor: Codable {
//    let id: String // Competitor ID - may not be needed
//    let nameContainer: CompetitorNameContainer // Container for competitor name
//    let overallScore: String // Overall score for event
//    let roundScores: [RoundScore] // Scoring information for each round
//
//    enum CodingKeys: String, CodingKey {
//        case id = "id"
//        case nameContainer = "athlete"
//        case overallScore = "score"
//        case roundScores = "linescores"
//    }
//}
//
//// This is a container for a competitor name
//struct CompetitorNameContainer: Codable {
//    let name: String
//
//    enum CodingKeys: String, CodingKey {
//        case name = "displayName"
//    }
//}
//
//// This is a container for a competitor round score
//struct RoundScore: Codable {
//    let value: Int? // Overall score
//
//    enum CodingKeys: String, CodingKey {
//        case value = "value"
//    }
//}

// MARK: - app.quicktype.io encode/decode helpers (unsure if needed)

//class JSONNull: Codable, Hashable {
//
//    public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
//        return true
//    }
//
//    public func hash(into hasher: inout Hasher) {
//        hasher.combine(0)
//    }
//
//    public init() {}
//
//    public required init(from decoder: Decoder) throws {
//        let container = try decoder.singleValueContainer()
//        if !container.decodeNil() {
//            throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
//        }
//    }
//
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.singleValueContainer()
//        try container.encodeNil()
//    }
//}
//
//class JSONCodingKey: CodingKey {
//    let key: String
//
//    required init?(intValue: Int) {
//        return nil
//    }
//
//    required init?(stringValue: String) {
//        key = stringValue
//    }
//
//    var intValue: Int? {
//        return nil
//    }
//
//    var stringValue: String {
//        return key
//    }
//}
//
//class JSONAny: Codable {
//
//    let value: Any
//
//    static func decodingError(forCodingPath codingPath: [CodingKey]) -> DecodingError {
//        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode JSONAny")
//        return DecodingError.typeMismatch(JSONAny.self, context)
//    }
//
//    static func encodingError(forValue value: Any, codingPath: [CodingKey]) -> EncodingError {
//        let context = EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode JSONAny")
//        return EncodingError.invalidValue(value, context)
//    }
//
//    static func decode(from container: SingleValueDecodingContainer) throws -> Any {
//        if let value = try? container.decode(Bool.self) {
//            return value
//        }
//        if let value = try? container.decode(Int64.self) {
//            return value
//        }
//        if let value = try? container.decode(Double.self) {
//            return value
//        }
//        if let value = try? container.decode(String.self) {
//            return value
//        }
//        if container.decodeNil() {
//            return JSONNull()
//        }
//        throw decodingError(forCodingPath: container.codingPath)
//    }
//
//    static func decode(from container: inout UnkeyedDecodingContainer) throws -> Any {
//        if let value = try? container.decode(Bool.self) {
//            return value
//        }
//        if let value = try? container.decode(Int64.self) {
//            return value
//        }
//        if let value = try? container.decode(Double.self) {
//            return value
//        }
//        if let value = try? container.decode(String.self) {
//            return value
//        }
//        if let value = try? container.decodeNil() {
//            if value {
//                return JSONNull()
//            }
//        }
//        if var container = try? container.nestedUnkeyedContainer() {
//            return try decodeArray(from: &container)
//        }
//        if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self) {
//            return try decodeDictionary(from: &container)
//        }
//        throw decodingError(forCodingPath: container.codingPath)
//    }
//
//    static func decode(from container: inout KeyedDecodingContainer<JSONCodingKey>, forKey key: JSONCodingKey) throws -> Any {
//        if let value = try? container.decode(Bool.self, forKey: key) {
//            return value
//        }
//        if let value = try? container.decode(Int64.self, forKey: key) {
//            return value
//        }
//        if let value = try? container.decode(Double.self, forKey: key) {
//            return value
//        }
//        if let value = try? container.decode(String.self, forKey: key) {
//            return value
//        }
//        if let value = try? container.decodeNil(forKey: key) {
//            if value {
//                return JSONNull()
//            }
//        }
//        if var container = try? container.nestedUnkeyedContainer(forKey: key) {
//            return try decodeArray(from: &container)
//        }
//        if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key) {
//            return try decodeDictionary(from: &container)
//        }
//        throw decodingError(forCodingPath: container.codingPath)
//    }
//
//    static func decodeArray(from container: inout UnkeyedDecodingContainer) throws -> [Any] {
//        var arr: [Any] = []
//        while !container.isAtEnd {
//            let value = try decode(from: &container)
//            arr.append(value)
//        }
//        return arr
//    }
//
//    static func decodeDictionary(from container: inout KeyedDecodingContainer<JSONCodingKey>) throws -> [String: Any] {
//        var dict = [String: Any]()
//        for key in container.allKeys {
//            let value = try decode(from: &container, forKey: key)
//            dict[key.stringValue] = value
//        }
//        return dict
//    }
//
//    static func encode(to container: inout UnkeyedEncodingContainer, array: [Any]) throws {
//        for value in array {
//            if let value = value as? Bool {
//                try container.encode(value)
//            } else if let value = value as? Int64 {
//                try container.encode(value)
//            } else if let value = value as? Double {
//                try container.encode(value)
//            } else if let value = value as? String {
//                try container.encode(value)
//            } else if value is JSONNull {
//                try container.encodeNil()
//            } else if let value = value as? [Any] {
//                var container = container.nestedUnkeyedContainer()
//                try encode(to: &container, array: value)
//            } else if let value = value as? [String: Any] {
//                var container = container.nestedContainer(keyedBy: JSONCodingKey.self)
//                try encode(to: &container, dictionary: value)
//            } else {
//                throw encodingError(forValue: value, codingPath: container.codingPath)
//            }
//        }
//    }
//
//    static func encode(to container: inout KeyedEncodingContainer<JSONCodingKey>, dictionary: [String: Any]) throws {
//        for (key, value) in dictionary {
//            let key = JSONCodingKey(stringValue: key)!
//            if let value = value as? Bool {
//                try container.encode(value, forKey: key)
//            } else if let value = value as? Int64 {
//                try container.encode(value, forKey: key)
//            } else if let value = value as? Double {
//                try container.encode(value, forKey: key)
//            } else if let value = value as? String {
//                try container.encode(value, forKey: key)
//            } else if value is JSONNull {
//                try container.encodeNil(forKey: key)
//            } else if let value = value as? [Any] {
//                var container = container.nestedUnkeyedContainer(forKey: key)
//                try encode(to: &container, array: value)
//            } else if let value = value as? [String: Any] {
//                var container = container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key)
//                try encode(to: &container, dictionary: value)
//            } else {
//                throw encodingError(forValue: value, codingPath: container.codingPath)
//            }
//        }
//    }
//
//    static func encode(to container: inout SingleValueEncodingContainer, value: Any) throws {
//        if let value = value as? Bool {
//            try container.encode(value)
//        } else if let value = value as? Int64 {
//            try container.encode(value)
//        } else if let value = value as? Double {
//            try container.encode(value)
//        } else if let value = value as? String {
//            try container.encode(value)
//        } else if value is JSONNull {
//            try container.encodeNil()
//        } else {
//            throw encodingError(forValue: value, codingPath: container.codingPath)
//        }
//    }
//
//    public required init(from decoder: Decoder) throws {
//        if var arrayContainer = try? decoder.unkeyedContainer() {
//            self.value = try JSONAny.decodeArray(from: &arrayContainer)
//        } else if var container = try? decoder.container(keyedBy: JSONCodingKey.self) {
//            self.value = try JSONAny.decodeDictionary(from: &container)
//        } else {
//            let container = try decoder.singleValueContainer()
//            self.value = try JSONAny.decode(from: container)
//        }
//    }
//
//    public func encode(to encoder: Encoder) throws {
//        if let arr = self.value as? [Any] {
//            var container = encoder.unkeyedContainer()
//            try JSONAny.encode(to: &container, array: arr)
//        } else if let dict = self.value as? [String: Any] {
//            var container = encoder.container(keyedBy: JSONCodingKey.self)
//            try JSONAny.encode(to: &container, dictionary: dict)
//        } else {
//            var container = encoder.singleValueContainer()
//            try JSONAny.encode(to: &container, value: self.value)
//        }
//    }
//}
//
