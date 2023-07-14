//
//  String+ESPNDate.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 6/22/23.
//

import Foundation

// This extension houses a date formatting helper function for the ESPN date format
extension String {
    
    // Convert the ESPN date string into a more usable format
    func espnDateStringToDouble() -> Double? {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.formatOptions = [.withFullDate]
        guard var date = formatter.date(from: self) else {
            print("Couldn't convert ESPN date string to date")
            return nil
        }
        
        // Get components from provided date
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        
        // Update hour, minute, and seconds components to 11:59PM
        components.hour = 23
        components.minute = 59
        components.second = 59
        
        // Rebuild the date object with the updated time components
        guard let endOfDay = calendar.date(from: components) else { return nil }
        date = endOfDay
        
        return date.timeIntervalSince1970
    }
}
