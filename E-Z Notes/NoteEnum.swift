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

}
