//
//  EZNoteScene.swift
//  E-Z Notes
//
//  Created by Matt Stone on 11/3/16.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import UIKit
import SpriteKit

class EZNoteScene: SKScene {
    var frameSize:CGSize
    let stave:Stave //TODO: change initialization to the init method (needs screen size)
    let notes:SKNode
    var touchNotePairs:[UITouch : Note]
    let touchThresholdScalar: CGFloat = 2.5 //increasing this value will make it easier to touch notes, but harder to distinguish (2.0 is a decent value)
    private(set) var showNoteLetters:Bool = false
    var targetScale:Scale? = nil
    let scaleButton:SKSpriteNode = SKSpriteNode(imageNamed:"NoteButton.png")
    let highlight:SKSpriteNode = SKSpriteNode(imageNamed: "note_highlight_e-z-noteApp.png")
    var playingScale:Bool = false
    var lock = Lock()
    
    init(Framesize framesize:CGSize){
        //init fields before calling super.init(size:)
        frameSize = framesize //NOTE: swift doesn't allow putting these inits in another method
        
        //correct if app was booted from landscape mode (swift will not allow me to put this in a function)
        if framesize.height > framesize.width {
            frameSize = framesize
        } else {
            frameSize = CGSize(width: framesize.height, height: framesize.width)
        }
        
        stave = Stave(Height: frameSize.width, Width: frameSize.height) //height and width are swapped in landscape

        notes = SKNode()
        touchNotePairs = [:]
        showNoteLetters = false
        super.init(size: framesize)
        //super init - now do set up for the fields(ie properties)
        
        //Set up the background
        self.backgroundColor = UIColor.white
        
        //Set up staves
        //set so that it starts at the 1/4 mark of the screen
        stave.position = CGPoint(x: 0, y: frameSize.width * 0.25) //width and height are swapped in landscape
        addChild(stave)
        
        //Set up notes
        createNotes()
        
        setUpScaleButton()
        addChild(scaleButton)
        
        //set up a default scale
        targetScale = Scale(Start: NoteEnum.C, Style: Scale.Style.Major)
        
        //set up the note highlight sprite
        setUpHighlightSprite()
        addChild(highlight)

        
        //Save last generated scene in static variable to act as singleton
        GlobalSpace.ezscene = self
        
        //Lock
        setUpLock()
        addChild(lock)
        
        //Debug/test
        
     
    }
    
    
    func setUpScaleButton(){
        //Set its position to top middle of screen
        scaleButton.position = CGPoint(x:frameSize.height * 0.5, y: frameSize.width * 0.95)
        
        //scale the button to a value relative to noteSpacing values
        let scaleFactor = stave.noteSpacing * 3 / scaleButton.size.height
        scaleButton.setScale(scaleFactor)
    }
    
    func setUpLock(){
        lock.position = CGPoint(x: frameSize.height * 0.05, y: frameSize.width * 0.95)
        
        //scale the lock image
        let scaleFactor = stave.noteSpacing * 3 / lock.getUnscaledSize().height
        lock.zPosition = 1
        lock.setScale(scaleFactor)
    }
    
    func setUpHighlightSprite(){
        highlight.position = CGPoint(x:frameSize.width * 0.1, y: frameSize.height * 0.1 )
        let highlightScaleFactor = calculateScaleFactor(MaxNoteSize: stave.noteSpacing * 2.5, CurrentNoteHeight: highlight.size.height)
        highlight.setScale(highlightScaleFactor)
        self.highlight.isHidden = true

    }
    
    func setAllNotesShowLetters(showNotes:Bool){
        for note:Note in notes.children as! [Note]{
            note.showLabel = showNotes
        }
    }
    
    func swapWidthHeight(_ sizeToSwap:CGSize) -> CGSize {
        return CGSize(width: sizeToSwap.height, height: sizeToSwap.width)
    }
    
    func createNotes(){
        
        let numOfNotes:Int = 8 //This represents the number of notes per line
        let equalSpacing:CGFloat = 1.0 / CGFloat(numOfNotes)
        let offsetX:CGFloat = equalSpacing / 2.0 * frameSize.height //reminder: height in landscape mode represents width
        let maximumNoteSize = 2 * stave.noteSpacing //note spacing is equal to half the distance between bars, thus mult by 2
        
        for i in 0..<numOfNotes { //init each note as a child of the notes
            let nextNote = Note(imageNamed: "ez_note_30x30.png")

            //scale the note for bar size
            let scaleFactor = calculateScaleFactor(MaxNoteSize: maximumNoteSize, CurrentNoteHeight: nextNote.size.height)
            //nextNote.setScale(scaleFactor)
            nextNote.customScale(ScaleFactor: scaleFactor)
            
            //height and width are swapped for landscape only applications
            nextNote.position = CGPoint(x: frameSize.height * CGFloat(i) * (equalSpacing) + offsetX,
                                        y: frameSize.width * (equalSpacing))
            //make z value place object later in draw queue (make it draw it above everything else)
            nextNote.zPosition = 1
            
            //Add note for drawing
            notes.addChild(nextNote)
        }
        addChild(notes)
        setAllNotesShowLetters(showNotes: showNoteLetters)
        
    }
    
    func calculateScaleFactor(MaxNoteSize maxSize:CGFloat, CurrentNoteHeight noteHeight:CGFloat) -> CGFloat{
        let floatCompareThreshold:CGFloat = 0.1
        
        //if note size is not the same as
        if abs(maxSize - noteHeight) > floatCompareThreshold {
            let maxToNoteRatio = maxSize / noteHeight
            return maxToNoteRatio
        } else {
            return 1
        }
    }
    
    func setShowNotes(ShowNoteLetters showNotesLettersAndOctaves:Bool){
        setAllNotesShowLetters(showNotes: showNotesLettersAndOctaves)
        self.showNoteLetters = showNotesLettersAndOctaves

    }
    
    required init?(coder aDecoder: NSCoder) {
        //do stuff related to this class before calling super
        frameSize = aDecoder.decodeObject(forKey: "frameSize") as! CGSize
        notes = aDecoder.decodeObject(forKey: "notes") as! SKNode
        stave = aDecoder.decodeObject(forKey: "stave") as! Stave

        touchNotePairs = aDecoder.decodeObject(forKey: "touchNotePairs") as! [UITouch : Note]
        super.init(coder: aDecoder)
    }
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(frameSize, forKey:"frameSize")
        aCoder.encode(notes, forKey: "notes")
        aCoder.encode(stave, forKey: "stave")
        aCoder.encode(touchNotePairs, forKey: "touchNotePairs")
    }
    
    override func update(_ currentTime: TimeInterval) {
        //this method is called every game loop cycle
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let touchPosition = touch?.location(in: notes)
        
        
        //loop through notes and see which note was touched
        for noteNode in notes.children {
            //Cast note:SKNode to a sprite node
            let note = noteNode as! Note //WARNING: if we decide to switch custom class, we will need to change cast
            
            //get position of current note
            let notesPosition = note.position
            
            //See if the current node was touched.
            if positionsAreSameWithinThreshold(notesPosition, touchPosition!, note.size) {
                if !lock.isLocked() {
                    // connect the note to the finger for touches moved
                    touchNotePairs[touch!] = note
                    
                    // check if taped two times, if so change state
                    if (touch?.tapCount)! > 1 {
                        note.changeNormSharpFlat()
                    }
                } else {
                  //Notes are locked, just play the note
                    note.playNote()
                }
            }
        }
        
        
        //check if testScale button was pressed, but do nothing if there is a note being dragged
        if touchNotePairs.count <= 0
            && positionsAreSameWithinThreshold(scaleButton.position,
                                               touch!.location(in: self),
                                               scaleButton.size)
        {
           scalePlay()
        }
        
        //check if lock button was pressed
        if positionsAreSameWithinThreshold(lock.position, touch!.location(in: self), lock.getScaledSize()){
            lock.toggle()
        }
    }

    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
      
        
        //check if the touch was associated with a note
        if let note = touchNotePairs[touch!]{
            //there was a note, try to snap it to a bar or let it fall to bottom of screen
            let futurePoint:CGPoint? = snapOrDropNote(note: note)
            stave.findNoteValueAndOctave(note: note, futureNotePosition: futurePoint, StavePosition: stave.position)
            if futurePoint != nil {
                note.playNote()
                note.updateNote(NotesUpdatedPoint: futurePoint!, StavePositionInView: stave.position, Stave: stave)
            }
        }
        
        //remove touch and note pair from dictionary
        touchNotePairs.removeValue(forKey: touch!) //first touch is guaranteed to not be nil
        
    }
    
    func snapOrDropNote(note:SKNode) -> CGPoint?{
        
        //if there is a position to snap to, then do it!
        if let snapToPoint = stave.findSnapPositionOrNil(PointToCheck: note.position, CurrentStavePos: stave.position){
            let move = SKAction.move(to: snapToPoint, duration: 0.25)   //duration is in seconds
            note.run(move)
            return snapToPoint //used to calculate the note's
            
        } else {
            //there is no snap position, let the note slowly fall to the bottom of the screen.
            //TODO implement this
            return nil  //this will be used to check the note value, make sure to return nil if note is falling to floor of app
        }
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches{
            if let note = touchNotePairs[touch] {
                note.position = touch.location(in: notes)
            }
        }
    }
    
    //This method takes two points, and determines if they intersect within some threshold.
    //This method uses the approach of using a size to estimate the radius of one point,
    //then use that to determine if touch happened.
    //
    //Another (and perhaps better approach) would be to create a temporary invisible note centered at the position of the finger,
    //then use the built in collision detection (using alpha masks) to see if the invisble note and the note being checked
    //have collided
    func positionsAreSameWithinThreshold(_ first:CGPoint, _ second:CGPoint, _ sizeImg:CGSize) -> Bool {
        //Assumes that the note image is roughly a square, but will use either the larger or smaller of the height/radius
        var limit = sizeImg.width > sizeImg.height ? sizeImg.width / 2.0 : sizeImg.height / 2.0
        limit *= touchThresholdScalar   //allows changing of threshold through class field
        
        //check that x and y are within the radius defined threshold(limit)
        if first.x < second.x + limit
            && first.x > second.x - limit
            && first.y < second.y + limit
            && first.y > second.y - limit
        {
            //the points overlap within the threshold, return true
            return true
            
        } else {
            return false
        }
    }
    
    
    
    
    func scalePlay(){
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
        let moveToPlayerNoteDelay = 0.5
        let moveToPlayerNote = SKAction.move(to: note.position, duration: moveToPlayerNoteDelay)
        self.highlight.run(moveToPlayerNote)
        //delay while the note moves
        Thread.sleep(forTimeInterval: moveToPlayerNoteDelay + 0.1)    //sleep for x seconds
        self.highlight.isHidden = false //sets to visible for first note.
    }

    func scaleHelperPlayCorrectNote(_ scaleNoteArray:[NoteEnum], _ currentPlayerNoteEnum:NoteEnum, _ currentScaleNoteEnum:NoteEnum,
                                    _ playersFirstOctave:OctaveEnum, _ playersFirstNote:NoteEnum, _ currPlayerNoteObj:Note,
                                    _ isFirstMethodCall:Bool, _ scaleDirection: Scale.Direction, _ targetScale: Scale){
        //CALCULATE THE WORKING OCTAVE
        let correctedOctaveForNote = scaleHelperFindContextCorrectedOctave(CurrentTestNote: currentPlayerNoteEnum,
                                                                           FirstScaleNote: scaleNoteArray[0],
                                                                           CurrentScaleNote: currentScaleNoteEnum,
                                                                           StartOctave: playersFirstOctave,
                                                                           isFirstMethodCall: isFirstMethodCall,
                                                                           direction: Scale.Direction.Ascending)
        //Invariant checks
        if correctedOctaveForNote == OctaveEnum.invalid || correctedOctaveForNote == OctaveEnum.one { return }
        if currPlayerNoteObj.representsOctave == nil { return }
        
        
        let playNoteDelay = 0.5
        //CHECK IF PLAYER SELECTED THE RIGHT NOTE POSITION (May or may not have choses right sharp/flat status)
        if currentPlayerNoteEnum == currentScaleNoteEnum && currPlayerNoteObj.representsOctave == correctedOctaveForNote{
            //play note (delay)
            currPlayerNoteObj.playNote()
            Thread.sleep(forTimeInterval: playNoteDelay)
            //TODO MAKE THIS CHECK PITCH
            let useSharpsTF:Bool = targetScale.scaleStyle == Scale.Style.Major ? true : false
            adjustNoteAppearanceForFlatSharp(note: currPlayerNoteObj, correctNoteEnum: currentScaleNoteEnum, useSharps: useSharpsTF)
            
        }
        //PLAYER DID NOT CHOOSE RIGHT NOTE POSITION (May or may not have choses right sharp/flat status)
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
            let useSharpsTF:Bool = targetScale.scaleStyle == Scale.Style.Major ? true : false
            var correctLocation = self.stave.getNotePosition(note: currentScaleNoteEnum, octave: octave, ProduceSharps: useSharpsTF,
                                                             stavePositionOffset: self.stave.position)
            
            //use sharps or flats? currently using sharps if scale is major and flats if the scale is minor
            stave.findNoteValueAndOctave(note: currPlayerNoteObj, futureNotePosition: correctLocation, StavePosition: stave.position)
            adjustNoteAppearanceForFlatSharp(note: currPlayerNoteObj, correctNoteEnum: currentScaleNoteEnum, useSharps: useSharpsTF)
            
            
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
            
            
        }
        
    }
    
    func scaleHelperCorrectPitch(targetScale:Scale, currScaleNoteEnum:NoteEnum, noteToModify:Note, correctLocation:CGPoint){
        //Choose whether or not to use flats/sharps based on if the scale is major or minor
        let useSharpsTF:Bool = targetScale.scaleStyle == Scale.Style.Major ? true : false
        
        //The below method will update the note's octave and note enumeration
        stave.findNoteValueAndOctave(note: noteToModify, futureNotePosition: correctLocation, StavePosition: stave.position)
        
        //This method will update the note's appearance based on the current Scale's note and will either use sharps or flats
        adjustNoteAppearanceForFlatSharp(note: noteToModify, correctNoteEnum: currScaleNoteEnum, useSharps: useSharpsTF)
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
            //make player note normal (even if it already was normal
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
    
    //method that allows segues back to this view controller from menus
    @IBAction func unwindToMenu(segue: UIStoryboardSegue) {}
}
