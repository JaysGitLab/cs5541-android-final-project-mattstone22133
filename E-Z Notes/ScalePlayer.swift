//
//  ScalePlayer.swift
//  E-Z Notes
//
//  Created by Matt Stone on 12/9/16.
//  Copyright © 2016 Matt Stone. All rights reserved.
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
        scalePlay()
        
    }
    
    func cleanUpState(){
        lastNotePoint = nil
    }
    
    private func scalePlay(){
        //Check if closure is already being executed, return from function call if already processing scale
        if playingScale { return }
        var isFirstNote = true
        
        //since this logic requires delays, it is be played in another thread to prevent freezing application
        let closure = {
            //1. NIL CHECK for SCALE
            if let scaleNoteArray = self.targetScale?.getNotes(){
                
                //2. SORT PLAYER NOTES; user reorganized notes - lowest note at x isn't lowest in container
                var sortedNotes:[SKNode] = self.notes.children.sorted(by: self.sortNodesByXReverse)
                let playersOctave:OctaveEnum? = self.scaleHelperFindPlayersFirstOctaveValue(array: sortedNotes as! [Note])
                let playersFirstNote:NoteEnum? = self.scaleHelperFindPlayersFirstNoteValue(array: sortedNotes as! [Note])
                if playersOctave == nil || playersFirstNote == nil {
                    return
                }
                self.playingScale = true
                
                //3. LOOP THROUGH SCALE
                for currentScaleNoteEnum:NoteEnum in scaleNoteArray{
                    //A. RESORT; resort the notes incase the player moved rearranged a note while playing scale
                    sortedNotes.sort(by: self.sortNodesByXReverse)
                    
                    //B. PLAY VALID NOTES
                    if let currentPlayerNoteEnum = (sortedNotes[sortedNotes.count - 1] as? Note)?.representsNote {
                        let currPlayerNoteObj = sortedNotes[sortedNotes.count - 1] as! Note
                        
                        //highlight note (delay) list is reverse sorted to make removing O(1)
                        self.scaleHelperHighlightNote(Note: currPlayerNoteObj)
                        
                        //playCorrectNote
                        self.scaleHelperPlayCorrectNote(scaleNoteArray, currentPlayerNoteEnum, currentScaleNoteEnum,
                                                        playersOctave!, playersFirstNote!, currPlayerNoteObj,
                                                        isFirstNote, Scale.Direction.Ascending, self.targetScale!)
                    }
                    //REMOVE CURRENT PLAYER NOTE - remove note from sortedNotes (reverse sorted, so removes from end)
                    sortedNotes.remove(at: sortedNotes.count - 1)
                    isFirstNote = false
                }
            }
            //4. CLEAN UP - high highlighter, and change playingScale state to false
            self.highlight.isHidden = true
            self.playingScale = false
        }
        
        //get a queue to pass closure (priorty method was deprecated iOS 8.0 and this is the new way to do it)
        let queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
        
        //pass the closure to another thread
        queue.async(execute: closure)
    }
    
    func scaleHelperHighlightNote(Note note:Note){
        //let moveToPlayerNoteDelay = 0.5       //this was converted to a property(field) for changing in settingss
        let moveToPlayerNote = SKAction.move(to: note.position, duration: moveToPlayerNoteDelay)
        self.highlight.run(moveToPlayerNote)
        //delay while the note moves
        Thread.sleep(forTimeInterval: moveToPlayerNoteDelay + 0.1)    //sleep for x seconds
        self.highlight.isHidden = false //sets to visible for first note.
    }
    
    //TODO either use this or remove this
    class IterVars {
        var scaleNoteArray:[NoteEnum]?
        var currentPlayerNoteEnum:NoteEnum?
        var currentScaleNoteEnum:NoteEnum?
        var playersFirstOctave:OctaveEnum?
        var playersFirstNote:NoteEnum?
        var currPlayerNoteObj:Note?
        var isFirstMethodCall:Bool?
        var scaleDirection: Scale.Direction?
    }
    
    func scaleHelperPlayCorrectNote(_ scaleNoteArray:[NoteEnum], _ currentPlayerNoteEnum:NoteEnum,
                                    _ currentRawScaleNoteEnum:NoteEnum,
                                    _ playersFirstOctave:OctaveEnum, _ playersFirstNote:NoteEnum, _ currPlayerNoteObj:Note,
                                    _ isFirstMethodCall:Bool, _ scaleDirection: Scale.Direction, _ targetScale: Scale){
        //make a mutable version of the currentScaleNoteEnum
        var currentScaleNoteEnum = currentRawScaleNoteEnum
        
        //CALCULATE THE WORKING OCTAVE
        var correctedOctaveForNote = scaleHelperFindContextCorrectedOctave(CurrentTestNote: currentPlayerNoteEnum,
                                                                           FirstScaleNote: scaleNoteArray[0],
                                                                           CurrentScaleNote: currentScaleNoteEnum,
                                                                           StartOctave: playersFirstOctave,
                                                                           isFirstMethodCall: isFirstMethodCall,
                                                                           direction: Scale.Direction.Ascending)
        //var overrideEnumAndLowerSemiTone = false
        
        //Invariant checks
        if correctedOctaveForNote == OctaveEnum.invalid || correctedOctaveForNote == OctaveEnum.one { return }
        if currPlayerNoteObj.representsOctave == nil { return }
        
        //CHECKING FOR DOUBLE LINE NOTES Check if note should be raised a line (if last note was on the same line) and dropped a semitone
        let useSharpsTF:Bool = targetScale.scaleStyle == Scale.Style.Major ? true : false
        let shouldRaiseTonesBar = noteOnSameLinePrevious(currentScaleNoteEnum, correctedOctaveForNote, useSharpsTF)
        if shouldRaiseTonesBar {
            //get a note on the line above, then later make this note flat (this will show the same note, but on the line above)
            currentScaleNoteEnum = stave.getWhiteKeyAbove(currentNote: currentScaleNoteEnum, useSharps: useSharpsTF)
            
            //re-calculate octave
            correctedOctaveForNote = scaleHelperFindContextCorrectedOctave(CurrentTestNote: currentPlayerNoteEnum,
                                                                           FirstScaleNote: scaleNoteArray[0],
                                                                           CurrentScaleNote: currentScaleNoteEnum,
                                                                           StartOctave: playersFirstOctave,
                                                                           isFirstMethodCall: isFirstMethodCall,
                                                                           direction: Scale.Direction.Ascending)
        }
        
        
        //let playNoteDelay = 0.5 //turned this into a property
        
        //CHECK IF PLAYER SELECTED THE RIGHT NOTE POSITION (May or may not have choses right sharp/flat status)
        if currentPlayerNoteEnum == currentScaleNoteEnum && currPlayerNoteObj.representsOctave == correctedOctaveForNote{
            //play note (delay)
            currPlayerNoteObj.playNote()
            Thread.sleep(forTimeInterval: playNoteDelay)
            
            //Note should be moved one line up, allow this logic to occur
            if shouldRaiseTonesBar {
                //adjustNoteAppearanceForFlatSharpCorrectNote(note: currPlayerNoteObj, correctNoteEnum: currentScaleNoteEnum,
                //                                 useSharps: useSharpsTF, forceToneDown: shouldRaiseTonesBar)
                specialNoteAppearanceAdjustment(note: currPlayerNoteObj, correctNoteEnum:currentScaleNoteEnum, useSharps:useSharpsTF)
            } else {
                adjustNoteAppearanceForFlatSharpCorrectNote(note: currPlayerNoteObj, correctNoteEnum: currentScaleNoteEnum,
                                                 useSharps: useSharpsTF, forceToneDown: shouldRaiseTonesBar)
            }
            lastNotePoint = currPlayerNoteObj.position
        }
        //PLAYER DID NOT CHOOSE CORRECT NOTE POSITION (May or may not have choses right sharp/flat status)
        else
        {
            let octave = correctedOctaveForNote
            //if player is holding note, remove it and lock it until it has been played
            for iter in self.touchNotePairs{ //!!! O(n) !!! - however, n will never be larger than 8 or 16
                if iter.value == currPlayerNoteObj{
                    self.touchNotePairs.removeValue(forKey: iter.key)
                    break
                }
            }
            //move note to correct y position (if needed) (delay)
            var correctLocation = self.stave.getNotePosition(note: currentScaleNoteEnum, octave: octave, ProduceSharps: useSharpsTF,
                                                             stavePositionOffset: self.stave.position)
            
            //use sharps or flats? currently using sharps if scale is major and flats if the scale is minor
            stave.findNoteValueAndOctave(note: currPlayerNoteObj, futureNotePosition: correctLocation, StavePosition: stave.position)
            adjustNoteAppearanceForFlatSharpCorrectNote(note: currPlayerNoteObj, correctNoteEnum: currentScaleNoteEnum, useSharps: useSharpsTF, forceToneDown: shouldRaiseTonesBar)
            
            
            correctLocation.x = currPlayerNoteObj.position.x
            
            //set up the move
            let moveCorrectPosition = SKAction.move(to: correctLocation, duration: playNoteDelay/4)
            currPlayerNoteObj.run(moveCorrectPosition)
            highlight.run(moveCorrectPosition)
            Thread.sleep(forTimeInterval: playNoteDelay/4 + 0.1) //delay so note will be positioned for snap
            
            currPlayerNoteObj.updateNote(NotesUpdatedPoint: correctLocation, StavePositionInView: self.stave.position, Stave: self.stave) //update the note enum
            
            //play note (delay) (must retype this code incase octave isn't valid
            currPlayerNoteObj.playNote()
            Thread.sleep(forTimeInterval: playNoteDelay)
            lastNotePoint = correctLocation
        }
        
    }
    
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
    func scaleHelperFindContextCorrectedOctave(CurrentTestNote currTestNote:NoteEnum,
                                               FirstScaleNote firstScaleNote:NoteEnum,
                                               CurrentScaleNote currScaleNote:NoteEnum,
                                               StartOctave startOctave:OctaveEnum,
                                               isFirstMethodCall:Bool, direction:Scale.Direction) -> OctaveEnum {
        //ONLY DIRECTION CURRENT SUPPORTED IS ASCENDING
        if direction == Scale.Direction.Ascending {
            //if the note is less than the start note, it is one octave higher than the start octave
            let testNoteLessThanStart = currScaleNote.rawValueStartingWithC() <= firstScaleNote.rawValueStartingWithC()
            if testNoteLessThanStart && !isFirstMethodCall {
                return OctaveEnum(rawValue: startOctave.rawValue + 1)!   //return an octave higher than what was started
            } else {
                //Current octave is valid
                return startOctave
            }
        } else if direction == Scale.Direction.Descending{
            //UNTESTED BRANCH - All scales are currently ascending
            let testNoteGreaterThanStart = currScaleNote.rawValueStartingWithC() >= firstScaleNote.rawValueStartingWithC()
            if testNoteGreaterThanStart && !isFirstMethodCall {
                return OctaveEnum(rawValue: startOctave.rawValue - 1)!   //return an octave higher than what was started
            } else {
                //Current octave is valid
                return startOctave
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
}
