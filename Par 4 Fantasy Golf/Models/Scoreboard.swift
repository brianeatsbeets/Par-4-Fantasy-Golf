//
//  Scoreboard.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 4/1/23.
//

struct Scoreboard: Codable {
    var eventId: String // events/0/id
    var startDate: String // events/0/date
    var endDate: String // events/0/endDate
    //var athletes: [Athlete] // Need to add espnId property
    
    enum CodingKeys: String, CodingKey {
        case eventId = "id"
        case startDate = "date"
        case endDate
    }
}
