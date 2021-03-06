//
//  OctaveEnum.swift
//  E-Z Notes
//
//  Created by Matt Stone on 11/17/16.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import UIKit

//This enumeration is to represent scientific pitch notation
//this app only supports octaves 2, 3, 4, 5, and 6
//Middle C is C4
//
//NOTE: Octaves start at C
enum OctaveEnum : Int {
    case one = -1
    case two = 0
    case three
    case four
    case five
    case invalid
    
    //below are used in calculating an octave shift for keyboard. octaves above min+3 are invalid, octaves below raw:0 are invalid
    static let minValidOct = 0;
    static let maxValidOct = minValidOct + 3
    
    static var startingNumber:Int {
        // C -> D -> E (off by 2)
        return 2
    }
    
    static func getOctave(barNumber:Int, note:Note) -> OctaveEnum{
        //create an offset for flats/sharps
        var sharpFlatOffset = 0
        if note.sharp {
            sharpFlatOffset = 1
        } else if note.flat {
            sharpFlatOffset = -1
        } else {
            sharpFlatOffset = 0
        }
        
        //bars start at E, octaves start at C, therefore add an offset (starting number)
        let convertedBarNumber = barNumber + startingNumber + sharpFlatOffset
        
        //find octave
        let octaveNumber = convertedBarNumber / 7   //7 is the number of notes in an octave
    
        switch octaveNumber {
        case 0:
            return OctaveEnum.two
        case 1:
            return OctaveEnum.three
        case 2:
            return OctaveEnum.four
        case 3:
            return OctaveEnum.five
        default:
            return OctaveEnum.invalid
        }
    }
    
    func toString() -> String{
        switch (self){
        case .two:
            return "2"
        case .three:
            return "3"
        case .four:
            return "4"
        case .five:
            return "5"
        default:
            return "INVALID_OCTAVE"
        }
    }
    
    func attemptGetLower() -> OctaveEnum{
        let new = self.rawValue - 1
        if(new >= OctaveEnum.minValidOct){
            return OctaveEnum(rawValue: new)!
        } else {
            return self
        }
    }
    
    func attemptGetHigher() -> OctaveEnum{
        let new = self.rawValue + 1
        if(new <= OctaveEnum.maxValidOct){
            return OctaveEnum(rawValue: new)!
        } else {
            return self
        }
    }
}
