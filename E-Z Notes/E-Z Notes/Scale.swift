//
//  Scale.swift
//  E-Z Notes
//
//  Created by Matt Stone on 11/30/16.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import Foundation

class Scale{
    //DEFINTIONS/CONSTANTS
    //W, W, S, W, W, W, S
    let majorSteps = [Tone.Whole,Tone.Whole,Tone.Semi,Tone.Whole,Tone.Whole,Tone.Whole,Tone.Semi]
    
    //W, H, W, W, H, W, W
    let minorSteps = [Tone.Whole,Tone.Semi,Tone.Whole,Tone.Whole,Tone.Semi,Tone.Whole,Tone.Whole]
    
    //PROPERTIES
    private(set) var ScaleStart:NoteEnum = NoteEnum.C
    private(set) var PitchesInScale:[NoteEnum]? = nil
    private(set) var scaleStyle:Style = Style.Major
    
    enum Tone : Int{
        case Semi = 1
        case Whole = 2
    }
    enum Style : Int{
        case Major = 0
        case Minor
    }
    
    enum Direction : Int {
        case Ascending = 0
        case Descending
    }
    
    init(Start start:NoteEnum, Style style:Scale.Style){
        generateScaleNotes(Start: start, Style: style)
        self.scaleStyle = style
    }
    
    func generateScaleNotes(Start start:NoteEnum, Style style:Scale.Style){
        //Clear old scale
        PitchesInScale = [NoteEnum]()
        self.scaleStyle = style
        switch style {
        case .Major:
            useStepsToGenerateNotes(Steps: majorSteps, Start: start)
            return
        case .Minor:
            useStepsToGenerateNotes(Steps: minorSteps, Start: start)
            return
        }
    }
    
    func useStepsToGenerateNotes(Steps scaleSteps:[Tone], Start start:NoteEnum){
        var iter:Int = start.rawValue

        PitchesInScale?.append(start)
        for currStep:Tone in scaleSteps {
            iter += currStep.rawValue
            let nextNote = NoteEnum(rawValue: iter % NoteEnum.count)
            PitchesInScale?.append(nextNote!) //modulus for bounds checking
        }
    }
    
    func getNotes() -> [NoteEnum]?{
        return PitchesInScale
    }
}
