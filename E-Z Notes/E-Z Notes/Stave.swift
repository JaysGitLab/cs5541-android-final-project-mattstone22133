//
//  Stave.swift
//  E-Z Notes
//
//  Created by Matt Stone on 11/8/16.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import UIKit
import SpriteKit

class Stave: SKNode {
    var barContainer:SKNode = SKNode()
    var screenHeight:CGFloat
    var screenWidth:CGFloat
    var numberOfBars = 26   //this number includes hidden bars
    var noteSpacing:CGFloat{
        get{
            //since logic behind note spacing is frequently changed, this getter is provided.
            //modify this getter so that noteSpacing logic is propogated throughout class.
            return screenHeight * 0.7 / CGFloat(numberOfBars)
        }
    }
    var trebleClef:SKSpriteNode = SKSpriteNode(imageNamed: "TrebleClef300x300.png")
    var bassClef:SKSpriteNode = SKSpriteNode(imageNamed: "BassClef300x300.png")
    
    init(Height height:CGFloat, Width width:CGFloat){
        self.screenHeight = height
        self.screenWidth = width
        super.init()
        
        //set up bars
        addChild(barContainer)
        buildBarsBottomUp()
        
        //set up clefs
        addChild(trebleClef)
        addChild(bassClef)
        setupClefs()
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        //frameSize = aDecoder.decodeObject(forKey: "frameSize") as! CGSize //EXAMPLE
        screenHeight = aDecoder.decodeObject(forKey: "screenHeight") as! CGFloat
        screenWidth = aDecoder.decodeObject(forKey: "screenWidth") as! CGFloat
        super.init(coder: aDecoder) //called after this object has be inits fields
    }
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder) //called before this object encodes any fields
        aCoder.encode(screenHeight, forKey: "screenHeight")
        aCoder.encode(screenWidth, forKey: "screenWidth")
        //aCoder.encode(frameSize, forKey:"frameSize") //EXAMPLE
    }
    
    func buildBarsBottomUp(){
        let noteSpacing = self.noteSpacing  //avoid recalculation overhead by saving in local variable
        for i in 0..<numberOfBars {
            let tempSprite = BarSprite(sizeBarNeedsToCover: screenWidth)
            tempSprite.position = CGPoint(x: 0, y: noteSpacing * CGFloat(i))
            barContainer.addChild(tempSprite)
            //update note values?
            
            //hide odd bars (or the very middle bar)
            if (i % 2 == 1 || barShouldBeHidden(barNumber: i)){
                tempSprite.setHidden(Hidden: true)
            }
        }
    }
    
    //function checks the value of a barNumber to determine if it is a special bar and should be hidden
    func barShouldBeHidden(barNumber:Int) -> Bool{
        let middleBar:Int = 12
        let hiddenBottonBar:Int = 0
        let hiddenTopBar:Int = 24
        
        return (barNumber == middleBar
            || barNumber == hiddenBottonBar
            || barNumber == hiddenTopBar)
        
    }
    
    func getHalfBarDistance() -> CGFloat{
        //return calculateNoteSpacing()
        return noteSpacing
    }
    
    //
    //NOTE: the note positions are relative to view frame, but stave position is relative to itself. We must convert one position.
    //To convert the note's position, we subtract the position of the stave (offset). This difference represents the position of the
    //note relative to the stave. This is done because position 0,0 of stave is actualy at offset.x and offset.y. The note's
    //position can be thought to include "offset.x and offset.y" (since the finger placed it visually on the stave). Thus,
    //we can subtract out these positions to get the true position of the note in local coordinate system of the stave.
    //
    func findSnapPositionOrNil(PointToCheck testPointUnconverted:CGPoint, CurrentStavePos offset:CGPoint) -> CGPoint?{
        //make test point that reflects the stave offset
        let testPoint = CGPoint(x: testPointUnconverted.x - offset.x, y: testPointUnconverted.y - offset.y)
        
        let ret:CGPoint? = nil
        let threshold = noteSpacing / 2     //if it is half way to a bar, snap to it. This will prevent collisions
        //let barWidthOffset = (barContainer.children[0] as! BarSprite).getImgHeight()
        
        for bar in barContainer.children {
            //test to see if y is within the threshold
            if abs(testPoint.y - bar.position.y) < threshold{
                //the return statement adds back the offset so that the point is realistic in the view that called this method
                return CGPoint(x: testPoint.x + offset.x, y: bar.position.y + offset.y) //snap to the same x, but different y
            }
        }
        
        return ret
    }
    
    //The note's position is not used, becuase it is likely being animated to a new position.
    //Instead, use the paramter futureNotePosition provided - this is expected to be the result of a notes animation
    //
    //NOTE: the note positions are relative to view frame, but stave position is relative to itself. We must convert one position.
    //To convert the note's position, we subtract the position of the stave (offset). This difference represents the position of the
    //note relative to the stave. This is done because position 0,0 of stave is actualy at offset.x and offset.y. The note's
    //position can be thought to include "offset.x and offset.y" (since the finger placed it visually on the stave). Thus,
    //we can subtract out these positions to get the true position of the note in local coordinate system of the stave.
    //
    func findNoteValueAndOctave(note:Note, futureNotePosition:CGPoint?, StavePosition offset:CGPoint?){
        if futureNotePosition == nil || offset == nil {
            return
        }
        
        //create a point that represents where the note is relative to the stave position
        let correctedPoint = CGPoint(x: futureNotePosition!.x - offset!.x, y: futureNotePosition!.y - offset!.y)
        
        //the calculation below is similar to the findSnapPositionOrNil, this could be included in that function
        //that being said, resources are not an issue for this app; therefore we are separating this from the snap function
        //because they provide two separate uses to the overall application. This keeps the app logic more easily understandable.
        var noteEnum:NoteEnum? = nil
        var octaveEnum:OctaveEnum? = nil
        let threshold = noteSpacing / 2     //if it is half way to a bar, snap to it. This will prevent collisions
        var barsCounted = 0
        
        //loop through all the bars and find the bar the note belongs to.
        for bar in barContainer.children {
            //test to see if y is within the threshold
            if abs(correctedPoint.y - bar.position.y) < threshold{
                //point found!
                noteEnum = findNoteEnumByBarNumber(barsCounted: barsCounted, note: note)
                octaveEnum = OctaveEnum.getOctave(barNumber: barsCounted, note: note) //TODO I think broken
                break;  //get out of loop
            }
            barsCounted += 1
        }
        
        //note.setNote(value: noteEnum)
        note.representsNote = noteEnum     //will be nil or a value
        note.representsOctave = octaveEnum //will be set ot nil or value
    }
    
    //this enum provides notes as seen on bar (no sharps or flats)
    //sharps and flats are calculated after the fact
    enum PseudoNote: Int{
        case E = 0
        case F
        case G
        case A
        case B
        case C
        case D
        static var count: Int { return PseudoNote.D.rawValue + 1}
    }
    
    func findNoteEnumByBarNumber(barsCounted:Int, note:Note) -> NoteEnum{
        //find the pseudo note (lacking sharps and flats)
        let pseudoIndex = barsCounted % PseudoNote.count                //trim this down to the range within pseudo notes
        let pNote:PseudoNote = Stave.PseudoNote(rawValue: pseudoIndex)!  // the pseudo  note!
        
        //NOTICE: if a value doesn't have a flat/sharp, the equivalent note will be returned (one note up/down)
        return convertPseudoNoteToNote(note: note, pNoteVal: pNote)
        
    }
    
    func convertPseudoNoteToNote(note:Note, pNoteVal:PseudoNote) -> NoteEnum {
        let normalNoteConvert = normalNoteTable(psuedoNote: pNoteVal)
        
        if note.normal {
            return normalNoteConvert
        } else if note.sharp {
            // let sharpUnconverted = normalNoteConvert.rawValue + 1
            //let sharpConverted = (sharpUnconverted + NoteEnum.count) % NoteEnum.count; //ensures it is within range and not below 0
            // return NoteEnum(rawValue: sharpConverted)!
            return NoteEnum.getSharpNote(note: normalNoteConvert)
        } else {
            // let flatUnconverted = normalNoteConvert.rawValue - 1
            // let flatConverted = (flatUnconverted + NoteEnum.count) % NoteEnum.count;  //ensures it is within range and not below 0
            // return NoteEnum(rawValue: flatConverted)!
            return NoteEnum.getFlatNote(note: normalNoteConvert)
        }
    }
    
    func normalNoteTable(psuedoNote:PseudoNote) -> NoteEnum{
        switch psuedoNote {
        case PseudoNote.A:
            return NoteEnum.A
        case PseudoNote.B:
            return NoteEnum.B
        case PseudoNote.C:
            return NoteEnum.C
        case PseudoNote.D:
            return NoteEnum.D
        case PseudoNote.E:
            return NoteEnum.E
        case PseudoNote.F:
            return NoteEnum.F
        case PseudoNote.G:
            return NoteEnum.G
        }
    }
    
    //This is for the when sharp and flat do not matter TODO: consider removing
    func pseudoNoteTable(normalNote:NoteEnum) -> PseudoNote {
        switch normalNote{
        case NoteEnum.A, NoteEnum.AsharpBb:
            return PseudoNote.A
        case NoteEnum.B:
            return PseudoNote.B
        case NoteEnum.C, NoteEnum.CsharpDb:
            return PseudoNote.C
        case NoteEnum.D, NoteEnum.DsharpEb:
            return PseudoNote.D
        case NoteEnum.E:
            return PseudoNote.E
        case NoteEnum.F, NoteEnum.FsharpGb:
            return PseudoNote.F
        case NoteEnum.G, NoteEnum.GsharpAb:
            return PseudoNote.G

        }
    }
    
    func pseudoNoteTableForSharps(normalNote:NoteEnum) -> PseudoNote {
        switch normalNote{
        case NoteEnum.A, NoteEnum.AsharpBb:
            return PseudoNote.A
        case NoteEnum.B:
            return PseudoNote.B
        case NoteEnum.C, NoteEnum.CsharpDb:
            return PseudoNote.C
        case NoteEnum.D, NoteEnum.DsharpEb:
            return PseudoNote.D
        case NoteEnum.E:
            return PseudoNote.E
        case NoteEnum.F, NoteEnum.FsharpGb:
            return PseudoNote.F
        case NoteEnum.G, NoteEnum.GsharpAb:
            return PseudoNote.G
            
        }
    }
    
    func pseudoNoteTableForFlats(normalNote:NoteEnum) -> PseudoNote {
        switch normalNote{
        case NoteEnum.A, NoteEnum.GsharpAb:
            return PseudoNote.A
        case NoteEnum.B, NoteEnum.AsharpBb:
            return PseudoNote.B
        case NoteEnum.C:
            return PseudoNote.C
        case NoteEnum.D, NoteEnum.CsharpDb:
            return PseudoNote.D
        case NoteEnum.E, NoteEnum.DsharpEb:
            return PseudoNote.E
        case NoteEnum.F:
            return PseudoNote.F
        case NoteEnum.G, NoteEnum.FsharpGb:
            return PseudoNote.G
            
        }
    }
    
    func setupClefs() {
        setupTrebleClef()
        setupBaseCleft()
        
    }
    
    func setupTrebleClef(){
        //Image related constants (in order to place circle in center, file size had to be larger
        let yCorrectionFactor:CGFloat = 5/8.0   // actual image is roughly 5/8 height of file
        let xCorrectionFactor:CGFloat = 1/3.0  // actual image is roughly 1/3 width of file
        
        //SCALE TREBLE CLEF so that is spans an entire bar, plus two steps above and below
        //get size of entire bar (note distance between 1 bar is 2*noteSpacing
        let entireStaveSize = (noteSpacing * 2) * 7 //5 bars + 2 spaces on edge
        let trebleClefYSize = trebleClef.size.height * yCorrectionFactor //img does not match height
        let yScaleFactor = entireStaveSize/trebleClefYSize
        trebleClef.yScale = yScaleFactor
        
        //X SCALE
        let specifiedScreenWidth = self.screenWidth * 0.08 //percentage of screen width (note landscape)
        let trebleCleftXSize = trebleClef.size.width * xCorrectionFactor
        let scaledWidth = specifiedScreenWidth / trebleCleftXSize
        trebleClef.xScale = scaledWidth //NOTE: clef image is huge to allow appropriate center
        
        //Position
        var gPoint:CGPoint = getNotePosition(note: NoteEnum.G,
                                             octave: OctaveEnum.four,
                                             stavePositionOffset: CGPoint(x:0, y:0)) //no offset, this is internal call
        gPoint.x = screenWidth * 0.1 //set x to 1/10th of the screen
        trebleClef.position = gPoint
    }
    
    func setupBaseCleft(){
        //Image related constants (in order to place circle in center, file size had to be larger
        let yCorrectionFactor:CGFloat = 13/16.0   // actual image is roughly * height of file
        let xCorrectionFactor:CGFloat = 5.0/8.0  // actual image is roughly * width of file
        
        //SCALE BASS CLEF so that is spans an entire bar, plus two steps above and below
        //get size of entire bar (note distance between 1 bar is 2*noteSpacing
        let entireStaveSize = (noteSpacing * 2) * 7 //5 bars + 2 spaces on edge
        let bassClefYSize = bassClef.size.height * yCorrectionFactor //img does not match height
        let yScaleFactor = entireStaveSize/bassClefYSize
        bassClef.yScale = yScaleFactor
        
        //X SCALE
        let specifiedScreenWidth = self.screenWidth * 0.08 //percentage of screen width (note landscape)
        let bassClefXSize = bassClef.size.width * xCorrectionFactor
        let scaledWidth = specifiedScreenWidth / bassClefXSize
        bassClef.xScale = scaledWidth //NOTE: clef image is huge to allow appropriate center
        
        //Position
        var fPoint:CGPoint = getNotePosition(note: NoteEnum.F,
                                             octave: OctaveEnum.three,
                                             stavePositionOffset: CGPoint(x:0, y:0)) //no offset, this is internal call
        fPoint.x = screenWidth * 0.1 //set x to 1/10th of the screen
        bassClef.position = fPoint
    }
    
    //Warning: behavior for sharps and flats is not intuitive. Sharps will be on the line of the base note, flats will below it.
    //e.g. Csharp will give you the location of C. Cflat will give you the location of B
    //@DEPRECATED IN FAVOR OF VERSION THAT SPECIFIES SHARP/FLAT BIAS
    func getNotePosition(note:NoteEnum, octave:OctaveEnum, stavePositionOffset:CGPoint) -> CGPoint{
        var noteDistance:Int
        var convertedNote:PseudoNote
        
        //find distance from lowest note to the note being tested (E is where the stave starts)
        if (note.rawValue >= NoteEnum.E.rawValue){ //Enum E has lower value, therefore distance is just subtraction
            
            //calculation
            convertedNote = pseudoNoteTable(normalNote: note)
            noteDistance = convertedNote.rawValue - PseudoNote.E.rawValue
        } else {//UNTESTED CONDITION
            //this should not happen, but is added in case internal enum logic is later changed
            convertedNote = pseudoNoteTable(normalNote: note)
            //(negative + total notes = note's pos)
            noteDistance = PseudoNote.E.rawValue - convertedNote.rawValue + PseudoNote.count
        }
        
        //add in the difference in octaves
        var octaveDifference = octave.rawValue - OctaveEnum.two.rawValue    //two is the lowest valid octave of the app
        
        //notes C and D are special in our scheme because we start counting notes at E. This means that C and D are one octave
        //higher than they should be in our position scheme. Our scheme has a "fake" octave that starts like this:
        // 2E,2F,2G, 2A, 2B, 3C, 3D ; therefore if C or D are encountered, then we have added one too many octaves.
        if convertedNote == PseudoNote.C || convertedNote == PseudoNote.D {
            octaveDifference -= 1
        }
        noteDistance = noteDistance + octaveDifference * PseudoNote.count
        
        let retx = screenWidth * 0.5 + stavePositionOffset.x
        let rety = CGFloat(noteDistance) * noteSpacing + stavePositionOffset.y
        return CGPoint(x: retx, y: rety) //UNTESTED
    }
    
    func getNotePosition(note:NoteEnum, octave:OctaveEnum, ProduceSharps sharpBias:Bool, stavePositionOffset:CGPoint) -> CGPoint{
        var noteDistance:Int
        var convertedNote:PseudoNote
        
        //find distance from lowest note to the note being tested (E is where the stave starts)
        if (note.rawValue >= NoteEnum.E.rawValue){ //Enum E has lower value, therefore distance is just subtraction
            
            //calculation
            convertedNote = sharpBias ? pseudoNoteTableForSharps(normalNote: note) : pseudoNoteTableForFlats(normalNote: note)
            noteDistance = convertedNote.rawValue - PseudoNote.E.rawValue
        } else {//UNTESTED CONDITION
            //this should not happen, but is added in case internal enum logic is later changed
            convertedNote = pseudoNoteTable(normalNote: note)
            //(negative + total notes = note's pos)
            noteDistance = PseudoNote.E.rawValue - convertedNote.rawValue + PseudoNote.count
        }
        
        //add in the difference in octaves
        var octaveDifference = octave.rawValue - OctaveEnum.two.rawValue    //two is the lowest valid octave of the app
        
        //notes C and D are special in our scheme because we start counting notes at E. This means that C and D are one octave
        //higher than they should be in our position scheme. Our scheme has a "fake" octave that starts like this:
        // 2E,2F,2G, 2A, 2B, 3C, 3D ; therefore if C or D are encountered, then we have added one too many octaves.
        if convertedNote == PseudoNote.C || convertedNote == PseudoNote.D {
            octaveDifference -= 1
        }
        noteDistance = noteDistance + octaveDifference * PseudoNote.count
        
        let retx = screenWidth * 0.5 + stavePositionOffset.x
        let rety = CGFloat(noteDistance) * noteSpacing + stavePositionOffset.y
        return CGPoint(x: retx, y: rety) //UNTESTED
    }
    
    func getWhiteKeyAbove(currentNote:NoteEnum, useSharps:Bool)-> NoteEnum{
        var whiteKeyConvert:PseudoNote
        //convert it to the white key
        if(useSharps){
            whiteKeyConvert = pseudoNoteTableForSharps(normalNote: currentNote)
        } else {
            whiteKeyConvert = pseudoNoteTableForFlats(normalNote: currentNote)
        }
        
        //return the note that represents line above it
        return normalNoteTable(psuedoNote: PseudoNote(rawValue: whiteKeyConvert.rawValue + 1 % PseudoNote.count)!)
    }

    
    func getTrebleClefSize() -> CGSize {
        return CGSize(width: trebleClef.size.width, height: trebleClef.size.height)
    }
    
    func getTrebleClefPosition() -> CGPoint {
        return CGPoint(x: trebleClef.position.x + self.position.x, y: trebleClef.position.y + self.position.y)
    }
    
}
