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
    
    //W, H, W, W, H, WH, H
    let harmonicMinorSteps = [Tone.Whole, Tone.Semi, Tone.Whole, Tone.Whole, Tone.Semi, Tone.Three, Tone.Semi]
    

    
    //PROPERTIES
    private(set) var ScaleStart:NoteEnum = NoteEnum.C
    private(set) var PitchesInScale:[NoteEnum]? = nil
    private(set) var scaleStyle:Style = Style.Major
    var scaleString:String? = nil
    
    enum Tone : Int{
        case Semi = 1
        case Whole = 2
        case Three = 3
    }
    enum Style : Int{
        case Major = 0
        case Minor
        case HarmonicMinor
        //case MelodicMinor not currently supported
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
        case .HarmonicMinor:
            useStepsToGenerateNotes(Steps: harmonicMinorSteps, Start: start)
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
    
    func setScaleBasedOnString(scale:String, Style style:Scale.Style){
        let choiceKey:NoteEnum
        switch(scale){
        case "C":
            choiceKey = NoteEnum.C
        case "C#", "Db":
            choiceKey = NoteEnum.CsharpDb
        case "D":
            choiceKey = NoteEnum.D
        case "D#","Eb":
            choiceKey = NoteEnum.DsharpEb
        case  "E":
            choiceKey = NoteEnum.E
        case "F":
            choiceKey = NoteEnum.F
        case "F#","Gb":
            choiceKey = NoteEnum.FsharpGb
        case "G":
            choiceKey = NoteEnum.G
        case "G#","Ab":
            choiceKey = NoteEnum.GsharpAb
        case "A":
            choiceKey = NoteEnum.A
        case "A#","Bb":
            choiceKey = NoteEnum.AsharpBb
        case "B":
            choiceKey = NoteEnum.B
        default:
            choiceKey = NoteEnum.C
        }
        generateScaleNotes(Start: choiceKey, Style: style)
    }
}
