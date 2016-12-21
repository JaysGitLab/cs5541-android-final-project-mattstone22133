//
//  NoteEnum.swift
//  E-Z Notes
//
//  Created by Matt Stone on 11/17/16.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import UIKit

enum NoteEnum : Int{

    case E = 0  //this is 0 because it is the lowest note implemented on bass cleft
    case F
    case FsharpGb
    case G
    case GsharpAb
    case A
    case AsharpBb
    case B
    case C
    case CsharpDb
    case D
    case DsharpEb
    static var count:Int {return NoteEnum.DsharpEb.rawValue + 1}

    
    func toStringTuple() -> (String, String){
        switch (self){
        case .E:
            return ("E", "")
        case .F:
            return ("F","")
        case .FsharpGb:
            return ("F", "SHARP")
        case .G:
            return ("G","")
        case .GsharpAb:
            return ("G","SHARP")
        case .A:
            return ("A","")
        case .AsharpBb:
            return ("A", "SHARP")
        case .B:
            return ("B", "")
        case .C:
            return ("C","")
        case .CsharpDb:
            return ("C","SHARP")
        case .D:
            return ("D","")
        case .DsharpEb:
            return ("D","SHARP")
        }
    }
    
    static func getSharpNote(note:NoteEnum) -> NoteEnum{
        let sharpUnconverted = note.rawValue + 1
        let sharpConverted = (sharpUnconverted) % NoteEnum.count;  //ensures it is within range and not below 0
        return NoteEnum(rawValue: sharpConverted)!
    }
    
    static func getFlatNote(note:NoteEnum) -> NoteEnum{
        let flatUnconverted = note.rawValue - 1
        let flatConverted = (flatUnconverted + NoteEnum.count) % NoteEnum.count;  //ensures it is within range and not below 0
        return NoteEnum(rawValue: flatConverted)!
    }
    
    //returns an Integer as if enum started with C (useful when doing calculatings between octaves)
    //This isn't necessarily bad code because the enum was originally used for calculating displacement on the bars.
    //This is a quick conversion to help with some logical problems when determining scales.
    func rawValueStartingWithC() -> Int{
        switch self{
        case .C: fallthrough
        case .CsharpDb: fallthrough
        case .D: fallthrough
        case .DsharpEb:
            //Get the difference between C and the current value to convert to enum values starting at C at 0
            return 0 + self.rawValue - NoteEnum.C.rawValue
        case .E: fallthrough
        case .F: fallthrough
        case .FsharpGb: fallthrough
        case .G: fallthrough
        case .GsharpAb: fallthrough
        case .A: fallthrough
        case .AsharpBb:fallthrough
        case .B:
            //E starts at 0, so add the difference starting at C (Dsharp - C gives use an offset value for starting at C at 0)
            return  self.rawValue + (NoteEnum.DsharpEb.rawValue - NoteEnum.C.rawValue)
        }
    }
    
    func isFlatOrSharp() -> Bool {
        switch self {
        case .CsharpDb: fallthrough
        case .DsharpEb: fallthrough
        case .FsharpGb: fallthrough
        case .GsharpAb: fallthrough
        case .AsharpBb:
            return true
        default:
            return false
        }
    }
    
}
