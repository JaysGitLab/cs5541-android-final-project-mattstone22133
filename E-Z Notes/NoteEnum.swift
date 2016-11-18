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
}
