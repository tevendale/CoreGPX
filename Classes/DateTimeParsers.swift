//
//  GPXDateTime.swift
//  CoreGPX
//
//  Created on 23/3/19.
//
//  Original code from: http://jordansmith.io/performant-date-parsing/
//  Modified to better suit CoreGPX's functionalities.
//

import Foundation


/**
 Date Parser for use when parsing GPX files, containing elements with date attributions.
 
 It can parse ISO8601 formatted date strings, along with year strings to native `Date` types.
 
 Formerly Named: `ISO8601DateParser` & `CopyrightYearParser`
 */
final class GPXDateParser {
    
    // MARK:- Supporting Variables
    
    #if !os(Linux)
    /// Caching Calendar such that it can be used repeatedly without reinitializing it.
    private static var calendarCache = [Int : Calendar]()
    /// Components of Date stored together
    private var components = DateComponents()
    #endif // !os(Linux)
    
    // MARK:- Individual Date Components
    
    private let year = UnsafeMutablePointer<Int>.allocate(capacity: 1)
    private let month = UnsafeMutablePointer<Int>.allocate(capacity: 1)
    private let day = UnsafeMutablePointer<Int>.allocate(capacity: 1)
    private let hour = UnsafeMutablePointer<Int>.allocate(capacity: 1)
    private let minute = UnsafeMutablePointer<Int>.allocate(capacity: 1)
    private let second = UnsafeMutablePointer<Int>.allocate(capacity: 1)
    
    deinit {
        year.deallocate()
        month.deallocate()
        day.deallocate()
        hour.deallocate()
        minute.deallocate()
        second.deallocate()
    }
    
    // MARK:- String To Date Parsers
    
    /// Parses an ISO8601 formatted date string as native Date type.
    func parse(date string: String?) -> Date? {
        guard var NonNilString = string else {
            return nil
        }
        
        // Test if date string has millseconds in it, and remove that portion if it does
        if NonNilString.contains(".") {
            let dotIndex = NonNilString.firstIndex(of: ".")
            if let indexDot = dotIndex {
                let indexEnd = NonNilString.index(indexDot, offsetBy: 3)
                NonNilString.removeSubrange(indexDot...indexEnd)
            }
        }
        
        return ISO8601DateFormatter().date(from: NonNilString)

        
//        print(NonNilString)
//        let newDate = "2014-02-25T17:51:21.000Z"
//        print(ISO8601DateFormatter().date(from: NonNilString))
//        ISO8601DateFormatter.Options.withFractionalSeconds
//        print(ISO8601DateFormatter().date(from: NonNilString))
        
        #if os(Linux)
        return ISO8601DateFormatter().date(from: NonNilString)
        #else // os(Linux)
        _ = withVaList([year, month, day, hour, minute,
                        second], { pointer in
            vsscanf(NonNilString, "%d-%d-%dT%d:%d:%dZ", pointer)
                            
        })
        

        components.year = year.pointee
        components.minute = minute.pointee
        components.day = day.pointee
        components.hour = hour.pointee
        components.month = month.pointee
        components.second = second.pointee
        
        print(year.pointee as Int)
        print(month.pointee)
        print(day.pointee)
        print(hour.pointee)
        print(minute.pointee)
        print(second.pointee)
        
        if let calendar = Self.calendarCache[0] {
            print(calendar.date(from: components))
            return calendar.date(from: components)
        }
        
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        Self.calendarCache[0] = calendar
        print(calendar.date(from: components))
        return calendar.date(from: components)
        #endif
    }
    
    /// Parses a year string as native Date type.
    func parse(year string: String?) -> Date? {
        guard let NonNilString = string else {
            return nil
        }
        
        _ = withVaList([year], { pointer in
            vsscanf(NonNilString, "%d", pointer)
            
        })
        
        #if os(Linux)
        return DateComponents(year: year.pointee).date
        #else // os(Linux)
        components.year = year.pointee
        
        if let calendar = Self.calendarCache[1] {
            return calendar.date(from: components)
        }
        
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        Self.calendarCache[1] = calendar
        return calendar.date(from: components)
        #endif
    }
}
