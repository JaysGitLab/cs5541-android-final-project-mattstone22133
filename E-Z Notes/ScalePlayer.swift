//
//  ScalePlayer.swift
//  E-Z Notes
//
//  Created by Matt Stone on 12/9/16.
//  Copyright © 2016 Matt Stone. All rights reserved.
//
// TODO: remove old deprecated functions or functions that or not longer used
//

import Foundation
import SpriteKit

class ScalePlayer {
    //Shared Variables with scene (these are initialized to dummy variables, change to optionals once all variables are found)
    var playingScale:Bool = false
    var targetScale:Scale?
    var notes:SKNode
    var highlight:SKSpriteNode
    var touchNotePairs:[UITouch : Note]
    var stave:Stave
    
    //interative state variables
    var lastNotePoint:CGPoint? = nil //this is used to help ensure that scale notes never end up on the same line
    
    //setting variables (delay timings)
    let moveToPlayerNoteDelay = 0.1
    let playNoteDelay = 0.1
    
    //playScale function shared fields (there are some default values initilized that will be changed with algorithm)
    var isFirstNote:Bool = false
    var scaleNoteArray:[NoteEnum]?
    var sortedNotes:[SKNode] = []
    var playersOctave:OctaveEnum? = nil
    var playersFirstNote:NoteEnum? = nil
    var currPlayerNoteObj:Note? = nil
    var correctedOctaveForNote:OctaveEnum? = nil
    var currentPlayerNoteEnum:NoteEnum?
    var currentScaleNoteEnum:NoteEnum?
    var hasLastNotePlayed:Bool = false
    var mockNoteLast:Note = Note()
    var mockNoteCurr:Note = Note()
    
    //same-line-note special check variables
    var specialCorrectionFlagForSameLineNotes = false
    var whiteNoteEnum:NoteEnum? = nil
    var whiteOctaveEnum:OctaveEnum? = nil


    
    //scale play correct note variables
    //var playersFirstOctave:OctaveEnum?
    //var isFirstMethodCall:Bool?
    //var scaleDirection: Scale.Direction?
    //var targetScale: Scale


    
    init(TargetScale targetScale:Scale,
         NoteCollection notes:SKNode,
         HighlightSprite highlight:SKSpriteNode,
         TouchNotePairs touchNotePairs:[UITouch : Note],
         StaveObject stave:Stave
        ){
        self.targetScale = targetScale
        self.notes = notes
        self.highlight = highlight
        self.touchNotePairs = touchNotePairs
        self.stave = stave
    }
    
    func playAScale(TargetScale targetScale:Scale,
                    NoteCollection notes:SKNode,
                    HighlightSprite highlight:SKSpriteNode,
                    TouchNotePairs touchNotePairs:[UITouch : Note],
                    StaveObject stave:Stave
                    ){
        self.targetScale = targetScale
        self.notes = notes
        self.highlight = highlight
        self.touchNotePairs = touchNotePairs
        self.stave = stave
        lastNotePoint = nil
        scalePlayInNewThread()
        
    }
    
    func cleanUpState(){
        lastNotePoint = nil
    }
    
    private func scalePlayInNewThread(){
        //Check if closure is already being executed, return from function call if already processing scale
        if playingScale { return }
        playingScale = true
        
        //since this logic requires delays, it is be played in another thread to prevent freezing application
        let closure = scalePlay
        
        //get a queue to pass closure (priorty method was deprecated iOS 8.0 and this is the new way to do it)
        let queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
        
        //pass the closure to another thread
        queue.async(execute: closure)
    }
    
    //WARNING this method should be called in a new thread to prevent freezing the app until the scale playing is over
    private func scalePlay(){
        //flag for the first note
        isFirstNote = true
        
        //1. NIL CHECK for SCALE
        if (self.targetScale?.getNotes() != nil){
            scaleNoteArray = self.targetScale?.getNotes()
            //2. SORT PLAYER NOTES; user reorganized notes - lowest note at x isn't lowest in container
            sortedNotes = self.notes.children.sorted(by: self.sortNodesByXReverse)
            
            //3. FIND START AND VALIDATE: find starting octave and note and make sure they are valid
            playersOctave = self.scaleHelperFindPlayersFirstOctaveValue(array: sortedNotes as! [Note])
            playersFirstNote = self.scaleHelperFindPlayersFirstNoteValue(array: sortedNotes as! [Note])
            if playersOctave == nil || playersFirstNote == nil {
                playingScale = false
                return
            }
            
            //4. LOOP THROUGH SCALE
            for currentScaleNoteEnum:NoteEnum in scaleNoteArray!{
                self.currentScaleNoteEnum = currentScaleNoteEnum
                
                //A. RESORT; resort the notes incase the player moved rearranged a note while playing scale
                sortedNotes.sort(by: sortNodesByXReverse)
                
                //B. PLAY VALID NOTES
                //if let currentPlayerNoteEnum = (sortedNotes[sortedNotes.count - 1] as? Note)?.representsNote {
                currentPlayerNoteEnum = (sortedNotes[sortedNotes.count - 1] as? Note)?.representsNote
                if (currentPlayerNoteEnum != nil){
                    currPlayerNoteObj = (sortedNotes[sortedNotes.count - 1] as! Note)
                    
                    //highlight note (delay) list is reverse sorted to make removing O(1)
                    highlightNote(Note: currPlayerNoteObj!)
                
                    playCorrectNote()
                }
                //REMOVE CURRENT PLAYER NOTE - remove note from sortedNotes (reverse sorted, so removes from end)
                sortedNotes.remove(at: sortedNotes.count - 1)
                isFirstNote = false
            }
        }
        //5. CLEAN UP - high highlighter, and change playingScale state to false
        highlight.isHidden = true
        playingScale = false
        resetFields()
    }

    func resetFields(){
         isFirstNote = false
         sortedNotes = []
         playersOctave = nil
         playersFirstNote = nil
         currPlayerNoteObj = nil
         correctedOctaveForNote = nil
         hasLastNotePlayed = false
         whiteNoteEnum = nil
         whiteOctaveEnum = nil
    }
    
    func highlightNote(Note note:Note){
        //let moveToPlayerNoteDelay = 0.5       //this was converted to a property(field) for changing in settingss
        let moveToPlayerNote = SKAction.move(to: note.position, duration: moveToPlayerNoteDelay)
        self.highlight.run(moveToPlayerNote)
        //delay while the note moves
        Thread.sleep(forTimeInterval: moveToPlayerNoteDelay + 0.1)    //sleep for x seconds
        self.highlight.isHidden = false //sets to visible for first note.
    }

    
    func playCorrectNote(){
        //calculate the correct octave for the player note
        correctedOctaveForNote = findContextCorrectedOctave(direction: Scale.Direction.Ascending)
        
        //check if currentNote will be on the same line as last note, if so then correct this
        correctIfCurrentCorrectNoteOnSameLineAsLastNote()
        
        //invariant checks (must come after octave calculation)
        if !playNoteInvariantCheckIsSafe(){ return }
            
        //CHECK IF PLAYER SELECTED THE RIGHT NOTE POSITION (May or may not have choses right sharp/flat status)
        if currentNoteIsCorrectlySetUp(){
            //Player set up the correct note for this position
            playCurrentNote()
        } else {
            //PLAYER DID NOT CHOOSE RIGHT NOTE POSITION (May or may not have choses right sharp/flat status)
            fixPlayerCurrentNote()
        }
        
    }
    
    //invariant1: assumes correctedOctaveForNote has been calculated
    func correctIfCurrentCorrectNoteOnSameLineAsLastNote(){
        //check if there is a last note played, if there isn't then make the current note the last note played (and return)
        if !hasLastNotePlayed {
            hasLastNotePlayed = true
            setMockNoteLast(currentScaleNoteEnum!, correctedOctaveForNote!)
            return
        }
        
        //clear any forcing that the last correction may have induced
        specialCorrectionFlagForSameLineNotes = false
        
        //get location of the last note played by the scale (function below updates its position)
        let lastPoint = stave.getNotePosition(note: mockNoteLast.representsNote!, octave: mockNoteLast.representsOctave!,
                                              ProduceSharps: shouldProduceSharps(), stavePositionOffset: stave.position)
        
        
        //get location of the current calcuated note to be played by the scale
        let currPoint = stave.getNotePosition(note: currentScaleNoteEnum!, octave: correctedOctaveForNote!,
                                                 ProduceSharps: shouldProduceSharps(), stavePositionOffset: stave.position)
        //determine if notes occupy the same white space
        if (yValuesSameWithinThreshold(lastPoint, currPoint, stave.noteSpacing * 0.1)){
            //if notes are same, then adjust the scales current calculations to be the same
            //ASCENDING SPECIFIC CODE BELOW
            specialCorrectionFlagForSameLineNotes = true
            if(currentScaleNoteEnum == NoteEnum.B) {
                //if note is B, then white key above is is on another octave
                whiteOctaveEnum = correctedOctaveForNote!.attemptGetHigher()
            }
            whiteNoteEnum = stave.getWhiteKeyAbove(currentNote: currentScaleNoteEnum!, useSharps: shouldProduceSharps())
            setMockNoteLast(whiteNoteEnum!, whiteOctaveEnum!) //updates position as a side effect
            return
        } else {
            //update the last note played to represent the current values
            setMockNoteLast(currentScaleNoteEnum!, correctedOctaveForNote!)
        }
        
        
    }

    func setMockNoteLast(_ lastNoteEnum:NoteEnum, _ lastOctEnum:OctaveEnum){
        //update mock note data
        mockNoteLast.representsNote = lastNoteEnum
        mockNoteLast.representsOctave = lastOctEnum
        
        //update mock note position (this is used to calculate the white note position later)
        mockNoteLast.position =
            stave.getNotePosition(
                note: lastNoteEnum,
                octave: lastOctEnum,
                ProduceSharps: shouldProduceSharps(),
                stavePositionOffset: stave.position)
    }
    
    func shouldProduceSharps() -> Bool{
        return targetScale!.scaleStyle == Scale.Style.Major ? true : false
    }
    
    
    func currentNoteIsCorrectlySetUp() -> Bool {
        
        
        //check octave
        if currentPlayerNoteEnum! != currentScaleNoteEnum! {
            return false
        }
        
        //check represents note
        if currPlayerNoteObj!.representsOctave! != correctedOctaveForNote{
            return false
        }
        
        // the repOctave and repNote should be correct, but we need to see if it is placed at the correct location in this situation
        if(specialCorrectionFlagForSameLineNotes){
            //this note requires special handling since the calculated value was determined to be on the same line as previous calc
            //ASCENDING SCALE SPECIFIC CODE
            //load mockNoteCurr with the player's current note information (in terms of WHITE KEYS)
            stave.findNoteValueAndOctave(note: mockNoteCurr, futureNotePosition: currPlayerNoteObj!.position,
                                         StavePosition: stave.position)

            //mockNote now contains the white key information of the player note, see if that information matches corrected
            let playerPoint = stave.getNotePosition(note: mockNoteCurr.representsNote!, octave: mockNoteCurr.representsOctave!,
                                                    ProduceSharps: shouldProduceSharps(), stavePositionOffset: stave.position)
            //mockNoteLast currently contains correct position for the corrected note (done in the checking for same line method)
            let correctPoint = mockNoteLast.position
            
            //check if positions are the same, if they are (within a threshold) then the player positioned the note correctly
            if(!yValuesSameWithinThreshold(playerPoint, correctPoint, stave.noteSpacing * 0.1)){
                return false
            }
        }
        
        
        return true
        //return currentPlayerNoteEnum! == currentScaleNoteEnum! && currPlayerNoteObj!.representsOctave! == correctedOctaveForNote
    }
    
    func playCurrentNote(){
        //play note (delay)
        currPlayerNoteObj!.playNote()
        Thread.sleep(forTimeInterval: playNoteDelay)
        
        if (!specialCorrectionFlagForSameLineNotes){
            //TODO MAKE THIS CHECK PITCH
            let useSharpsTF:Bool = shouldProduceSharps()
            adjustNoteAppearanceForFlatSharp(note: currPlayerNoteObj!, correctNoteEnum: currentScaleNoteEnum!, useSharps: useSharpsTF)
        }
    }
    
    func fixPlayerCurrentNote(){
        let octave = correctedOctaveForNote!
        
        //if player is holding note, remove it and lock it until it has been played
        for iter in self.touchNotePairs{ //!!! O(n) !!! - however, n will never be larger than 8 or 16
            if iter.value == currPlayerNoteObj{
                self.touchNotePairs.removeValue(forKey: iter.key)
                break
            }
        }
        //move note to correct y position (if needed) (delay)
        let useSharpsTF:Bool = shouldProduceSharps()
        var correctLocation = self.stave.getNotePosition(note: currentScaleNoteEnum!, octave: octave, ProduceSharps: useSharpsTF,
                                                         stavePositionOffset: self.stave.position)
        
        if(specialCorrectionFlagForSameLineNotes){
            correctLocation = mockNoteLast.position
        }
        
        //use sharps or flats? currently using sharps if scale is major and flats if the scale is minor
        //update player note value
        stave.findNoteValueAndOctave(note: currPlayerNoteObj!, futureNotePosition: correctLocation, StavePosition: stave.position)
        
        if (!specialCorrectionFlagForSameLineNotes){
            //movement will make a black note, so change it to sharp or flat depending on what is to be used
            adjustNoteAppearanceForFlatSharp(note: currPlayerNoteObj!, correctNoteEnum: currentScaleNoteEnum!, useSharps: useSharpsTF)
        } else {
            //this means that the note requires special handling, simply lower the note by 1 semitone (specific to ascending scales)
            currPlayerNoteObj!.lowerByOneSemitone()
            
            //sometimes the player may have a sharp in teh wrong location, and an additional drop in semi-tone may be requried
            if (currPlayerNoteObj!.representsNote != currentScaleNoteEnum){
                currPlayerNoteObj!.lowerByOneSemitone()
            }
        }
        
        
        correctLocation.x = currPlayerNoteObj!.position.x
        
        //set up the move
        let moveCorrectPosition = SKAction.move(to: correctLocation, duration: playNoteDelay/4)
        currPlayerNoteObj!.run(moveCorrectPosition)
        highlight.run(moveCorrectPosition)
        Thread.sleep(forTimeInterval: playNoteDelay/4 + 0.1) //delay so note will be positioned for snap
        
        currPlayerNoteObj!.updateNote(NotesUpdatedPoint: correctLocation, StavePositionInView: self.stave.position, Stave: self.stave) //update the note enum
        
        //play note (delay) (must retype this code incase octave isn't valid
        currPlayerNoteObj!.playNote()
        Thread.sleep(forTimeInterval: playNoteDelay)
    }

    func playNoteInvariantCheckIsSafe() -> Bool {
        if currPlayerNoteObj == nil {
            return false
        }
        
        if targetScale == nil {
            return false
        }
        
        if currentScaleNoteEnum == nil {
            return false
        }
        
        if currentPlayerNoteEnum == nil {
            return false
        }
        
        if correctedOctaveForNote == OctaveEnum.invalid || correctedOctaveForNote == OctaveEnum.one { return false }
        
        if currPlayerNoteObj!.representsOctave == nil { return false }
        return true;
    }
    
    //@deprecated - remove these after scale playing is bug free
    //Compares agaisnt the lastNotePosition field and determines if current note was previous on the same line
    func noteOnSameLinePrevious(_ currentScaleNoteEnum:NoteEnum, _ correctedOctaveForNote:OctaveEnum,_ useSharpsTF:Bool) -> Bool {
        let calculatedPosition = stave.getNotePosition(note: currentScaleNoteEnum, octave: correctedOctaveForNote,
                                                       ProduceSharps: useSharpsTF, stavePositionOffset: stave.position)
        if lastNotePoint != nil {
            return yValuesSameWithinThreshold(calculatedPosition, lastNotePoint!, stave.noteSpacing * 0.1)
        } else {
            return false
        }
    }
    
    /*
    func scaleHelperCorrectPitch(targetScale:Scale, currScaleNoteEnum:NoteEnum, noteToModify:Note, correctLocation:CGPoint){
        //Choose whether or not to use flats/sharps based on if the scale is major or minor
        let useSharpsTF:Bool = targetScale.scaleStyle == Scale.Style.Major ? true : false
        
        //The below method will update the note's octave and note enumeration
        stave.findNoteValueAndOctave(note: noteToModify, futureNotePosition: correctLocation, StavePosition: stave.position)
        
        //This method will update the note's appearance based on the current Scale's note and will either use sharps or flats
        adjustNoteAppearanceForFlatSharp(note: noteToModify, correctNoteEnum: currScaleNoteEnum, useSharps: useSharpsTF)
    }
    */


    //Assumes the corrected noteEnum has be passed, but the flat version must be generated (if sharp, flat is normal)
    //@Assumes correctedNoteEnum is the correct bar position
    //@assumes note is the previous note (and that sharp/flat data can be extracted) 
    //
    //Note, there cannot be two flats on the same bar with the way ascending scales are made
    func specialNoteAppearanceAdjustment(note:Note, correctNoteEnum: NoteEnum, useSharps:Bool) {
        //TODO incomplete
        
        //create a mutable version the parameter
        //var correctNoteEnumFiltered:NoteEnum = correctNoteEnum
        var forceFlat:Bool = false
        var forceNormal:Bool = false
        
        if (note.normal){
            forceFlat = true
        } else if (note.sharp){
            forceNormal = true
        }
        //correctNoteEnumFiltered = NoteEnum.getFlatNote(note: correctNoteEnum)
        
        if forceFlat {
            note.make(Pitch: Note.Pitch.Flat)
        } else if forceNormal {
            note.make(Pitch: Note.Pitch.Normal)
        }
        
        
    }
    
    
    func adjustNoteAppearanceForFlatSharpCorrectNote(note:Note, correctNoteEnum: NoteEnum, useSharps:Bool, forceToneDown:Bool){
        if correctNoteEnum.isFlatOrSharp(){
            if useSharps {
                //make player's note sharp
                note.make(Pitch: Note.Pitch.Sharp)
                
            } else {
                //make player's note flat
                note.make(Pitch: Note.Pitch.Flat)
            }
        } else {
            //only make note normal if it the note's position matches the normal position (otherwise it may be an normal note derived  by accidental (sharp/flat)
            if let notesOctave = note.representsOctave {
                let thisNotesPos = stave.getNotePosition(note: correctNoteEnum, octave: notesOctave, ProduceSharps: useSharps, stavePositionOffset: stave.position)
                //Only convert note to normal if it is positioned in the correct spot (Cflat will register as B, but shouldn't be normal)
                if positionsSameWithinThreshold(note.position, thisNotesPos, stave.noteSpacing * 0.1){
                    //make player note normal (even if it already was normal)
                    note.make(Pitch: Note.Pitch.Normal)
                }
            }
            
        }
    }
    
    func adjustNoteAppearanceForFlatSharp(note:Note, correctNoteEnum:NoteEnum, useSharps:Bool){
        if correctNoteEnum.isFlatOrSharp() {
            if useSharps {
                //make player's note sharp
                note.make(Pitch: Note.Pitch.Sharp)
                
            } else {
                //make player's note flat
                note.make(Pitch: Note.Pitch.Flat)
            }
        } else {
            //only make note normal if it the note's position matches the normal position (otherwise it may be an normal note derived  by accidental (sharp/flat)
            if let notesOctave = note.representsOctave {
                let thisNotesPos = stave.getNotePosition(note: correctNoteEnum, octave: notesOctave, ProduceSharps: useSharps, stavePositionOffset: stave.position)
                //Only convert note to normal if it is positioned in the correct spot (Cflat will register as B, but shouldn't be normal)
                if positionsSameWithinThreshold(note.position, thisNotesPos, stave.noteSpacing * 0.1){
                    //make player note normal (even if it already was normal)
                    note.make(Pitch: Note.Pitch.Normal)
                }
            }
            //make player note normal (even if it already was normal)
            note.make(Pitch: Note.Pitch.Normal)
        }
    }
    
    
    func scaleHelperFindPlayersFirstOctaveValue(array:[Note]) -> OctaveEnum? {
        //the array is reverse for quick removal
        for note in array.reversed() {
            if let firstOctave = note.representsOctave{
                return firstOctave
            }
        }
        return nil
    }
    
    func scaleHelperFindPlayersFirstNoteValue(array:[Note]) -> NoteEnum?{
        //the array is reverse for quick removal
        for note in array.reversed() {
            if let firstOctave = note.representsNote{
                return firstOctave
            }
        }
        return nil
    }
    
    //helper function to determine the octave the correct note should be in (based on the first octave the player chose)
    //If the scale is ascending, then the octave should be the same as the first notes octave until
    func findContextCorrectedOctave(direction:Scale.Direction) -> OctaveEnum {
        
        //ONLY DIRECTION CURRENT SUPPORTED IS ASCENDING
        if direction == Scale.Direction.Ascending {
            
            //if the note is less than the start note, it is one octave higher than the start octave
            let testNoteLessThanStart =
                    currentScaleNoteEnum!.rawValueStartingWithC() <= (scaleNoteArray?[0])!.rawValueStartingWithC()
            
            //true means there should be an octave correction for note
            if testNoteLessThanStart && !isFirstNote {
                return OctaveEnum(rawValue: playersOctave!.rawValue + 1)!   //return an octave higher than what was started
            } else {
                //Current octave is valid
                return playersOctave!
            }
            
        }
        
        
        
        
        //UNTESTED BRANCH - All scales are currently ascending (added this code incase future support)
        else if direction == Scale.Direction.Descending{
            let testNoteGreaterThanStart = currentScaleNoteEnum!.rawValueStartingWithC() >= (scaleNoteArray?[0])!.rawValueStartingWithC()
            if testNoteGreaterThanStart && !isFirstNote {
                return OctaveEnum(rawValue: playersOctave!.rawValue - 1)!   //return an octave higher than what was started
            } else {
                //Current octave is valid
                return playersOctave!
            }
        } else {
            return OctaveEnum.invalid
        }
    }
    
    func sortNodesByXReverse(first:SKNode, second:SKNode) -> Bool{
        return first.position.x > second.position.x
    }
    
    //This method has no ties to any properties (thresholdScalar, etc)
    func positionsSameWithinThreshold(_ first:CGPoint, _ second:CGPoint, _ threshold:CGFloat) -> Bool {
        //check that x and y are within the radius defined threshold(limit)
        if first.x < second.x + threshold
            && first.x > second.x - threshold
            && first.y < second.y + threshold
            && first.y > second.y - threshold
        {
            //the points overlap within the threshold, return true
            return true
            
        } else {
            return false
        }
    }
    
    //This method has no ties to any properties (thresholdScalar, etc)
    func yValuesSameWithinThreshold(_ first:CGPoint, _ second:CGPoint, _ threshold:CGFloat) -> Bool {
        //check that x and y are within the radius defined threshold(limit)
        if first.y < second.y + threshold
            && first.y > second.y - threshold
        {
            //the points overlap within the threshold, return true
            return true
            
        } else {
            return false
        }
    }
    
    enum overrideFlatSharpStatus {
        case overrideToDownSemitone
        case overrideToUpSemitone
        case normal
    }
    
    //broken version
    //    func scaleHelperPlayCorrectNote(_ scaleNoteArray:[NoteEnum], _ currentPlayerNoteEnum:NoteEnum,
    //                                    _ currentRawScaleNoteEnum:NoteEnum,
    //                                    _ playersFirstOctave:OctaveEnum, _ playersFirstNote:NoteEnum, _ currPlayerNoteObj:Note,
    //                                    _ isFirstMethodCall:Bool, _ scaleDirection: Scale.Direction, _ targetScale: Scale){
    //        //make a mutable version of the currentScaleNoteEnum
    //        var currentScaleNoteEnum = currentRawScaleNoteEnum
    //
    //        //CALCULATE THE WORKING OCTAVE
    //        var correctedOctaveForNote = scaleHelperFindContextCorrectedOctave(CurrentTestNote: currentPlayerNoteEnum,
    //                                                                           FirstScaleNote: scaleNoteArray[0],
    //                                                                           CurrentScaleNote: currentScaleNoteEnum,
    //                                                                           StartOctave: playersFirstOctave,
    //                                                                           isFirstMethodCall: isFirstMethodCall,
    //                                                                           direction: Scale.Direction.Ascending)
    //        //var overrideEnumAndLowerSemiTone = false
    //
    //        //Invariant checks
    //        if correctedOctaveForNote == OctaveEnum.invalid || correctedOctaveForNote == OctaveEnum.one { return }
    //        if currPlayerNoteObj.representsOctave == nil { return }
    //
    //        //CHECKING FOR DOUBLE LINE NOTES Check if note should be raised a line (if last note was on the same line) and dropped a semitone
    //        let useSharpsTF:Bool = targetScale.scaleStyle == Scale.Style.Major ? true : false
    //        let shouldRaiseTonesBar = noteOnSameLinePrevious(currentScaleNoteEnum, correctedOctaveForNote, useSharpsTF)
    //        if shouldRaiseTonesBar {
    //            //get a note on the line above, then later make this note flat (this will show the same note, but on the line above)
    //            currentScaleNoteEnum = stave.getWhiteKeyAbove(currentNote: currentScaleNoteEnum, useSharps: useSharpsTF)
    //
    //            //re-calculate octave
    //            correctedOctaveForNote = scaleHelperFindContextCorrectedOctave(CurrentTestNote: currentPlayerNoteEnum,
    //                                                                           FirstScaleNote: scaleNoteArray[0],
    //                                                                           CurrentScaleNote: currentScaleNoteEnum,
    //                                                                           StartOctave: playersFirstOctave,
    //                                                                           isFirstMethodCall: isFirstMethodCall,
    //                                                                           direction: Scale.Direction.Ascending)
    //        }
    //
    //
    //        //let playNoteDelay = 0.5 //turned this into a property
    //
    //        //CHECK IF PLAYER SELECTED THE RIGHT NOTE POSITION (May or may not have choses right sharp/flat status)
    //        if currentPlayerNoteEnum == currentScaleNoteEnum && currPlayerNoteObj.representsOctave == correctedOctaveForNote{
    //            //play note (delay)
    //            currPlayerNoteObj.playNote()
    //            Thread.sleep(forTimeInterval: playNoteDelay)
    //
    //            //Note should be moved one line up, allow this logic to occur
    //            if shouldRaiseTonesBar {
    //                //adjustNoteAppearanceForFlatSharpCorrectNote(note: currPlayerNoteObj, correctNoteEnum: currentScaleNoteEnum,
    //                //                                 useSharps: useSharpsTF, forceToneDown: shouldRaiseTonesBar)
    //                specialNoteAppearanceAdjustment(note: currPlayerNoteObj, correctNoteEnum:currentScaleNoteEnum, useSharps:useSharpsTF)
    //            } else {
    //                adjustNoteAppearanceForFlatSharpCorrectNote(note: currPlayerNoteObj, correctNoteEnum: currentScaleNoteEnum,
    //                                                 useSharps: useSharpsTF, forceToneDown: shouldRaiseTonesBar)
    //            }
    //            lastNotePoint = currPlayerNoteObj.position
    //        }
    //        //PLAYER DID NOT CHOOSE CORRECT NOTE POSITION (May or may not have choses right sharp/flat status)
    //        else
    //        {
    //            let octave = correctedOctaveForNote
    //            //if player is holding note, remove it and lock it until it has been played
    //            for iter in self.touchNotePairs{ //!!! O(n) !!! - however, n will never be larger than 8 or 16
    //                if iter.value == currPlayerNoteObj{
    //                    self.touchNotePairs.removeValue(forKey: iter.key)
    //                    break
    //                }
    //            }
    //            //move note to correct y position (if needed) (delay)
    //            var correctLocation = self.stave.getNotePosition(note: currentScaleNoteEnum, octave: octave, ProduceSharps: useSharpsTF,
    //                                                             stavePositionOffset: self.stave.position)
    //
    //            //use sharps or flats? currently using sharps if scale is major and flats if the scale is minor
    //            stave.findNoteValueAndOctave(note: currPlayerNoteObj, futureNotePosition: correctLocation, StavePosition: stave.position)
    //            adjustNoteAppearanceForFlatSharpCorrectNote(note: currPlayerNoteObj, correctNoteEnum: currentScaleNoteEnum, useSharps: useSharpsTF, forceToneDown: shouldRaiseTonesBar)
    //
    //
    //            correctLocation.x = currPlayerNoteObj.position.x
    //
    //            //set up the move
    //            let moveCorrectPosition = SKAction.move(to: correctLocation, duration: playNoteDelay/4)
    //            currPlayerNoteObj.run(moveCorrectPosition)
    //            highlight.run(moveCorrectPosition)
    //            Thread.sleep(forTimeInterval: playNoteDelay/4 + 0.1) //delay so note will be positioned for snap
    //
    //            currPlayerNoteObj.updateNote(NotesUpdatedPoint: correctLocation, StavePositionInView: self.stave.position, Stave: self.stave) //update the note enum
    //            
    //            //play note (delay) (must retype this code incase octave isn't valid
    //            currPlayerNoteObj.playNote()
    //            Thread.sleep(forTimeInterval: playNoteDelay)
    //            lastNotePoint = correctLocation
    //        }
    //        
    //    }
    
}
