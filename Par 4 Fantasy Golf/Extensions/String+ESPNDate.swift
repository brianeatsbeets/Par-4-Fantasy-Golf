//
//  String+ESPNDate.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 6/22/23.
//

import Foundation

// This extension converts the ESPN date string into more usable formats
extension String {
    
    // Return a since-epoch double
    func espnDateStringToDouble() -> Double? {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.formatOptions = [.withFullDate]
        guard let date = formatter.date(from: self) else {
            print("Couldn't convert ESPN date string to date")
            return nil
        }
        return date.timeIntervalSince1970
    }
}
