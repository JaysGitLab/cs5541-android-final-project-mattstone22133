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
    let frameSize:CGSize
    let stave:Stave //TODO: change initialization to the init method (needs screen size)
    let notes:SKNode
    var touchNotePairs:[UITouch : SKNode]
    let touchThresholdScalar: CGFloat = 2.0 //increasing this value will make it easier to touch notes, but harder to distinguish

    
    
    //testing fields
    //let bar = BarSprite(sizeBarNeedsToCover: 300) //TODO
    
    
    init(Framesize framesize:CGSize){
        //init fields before calling super.init(size:)
        frameSize = framesize //NOTE: swift doesn't allow putting these inits in another method
        stave = Stave(Height: frameSize.width, Width: frameSize.height) //height and width are swapped in landscape
        notes = SKNode()
        touchNotePairs = [:]
        super.init(size: framesize)
        //super init - now do set up for the fields(ie properties)
        
        //Set up the background
        self.backgroundColor = UIColor.white
        
        //Set up staves
        //set so that it starts at the 1/3 mark of the screen
        stave.position = CGPoint(x: 0, y: framesize.width * 0.25) //width and height are swapped in landscape
        addChild(stave)
        
        //Set up notes
        createNotes()
        
        //debugging/testing 
        //let bar = BarSprite(sizeBarNeedsToCover: framesize.height)
        //self.addChild(bar)
        //bar.position = CGPoint(x: 0, y: 100)
        //self.addChild(SKSpriteNode(imageNamed: "ez_bar_2x100.png"))
        //self.addChild(SKSpriteNode(imageNamed: "GenericActorSprite.png"))

 
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
            nextNote.setScale(scaleFactor)
            
            //height and width are swapped for landscape only applications
            nextNote.position = CGPoint(x: frameSize.height * CGFloat(i) * (equalSpacing) + offsetX,
                                        y: frameSize.width * (equalSpacing))
            //make z value place object later in draw queue (make it draw it above everything else)
            nextNote.zPosition = 1
            
            //Add note for drawing
            notes.addChild(nextNote)
        }
        addChild(notes)
        
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
    
    required init?(coder aDecoder: NSCoder) {
        //do stuff related to this class before calling super
        frameSize = aDecoder.decodeObject(forKey: "frameSize") as! CGSize
        notes = aDecoder.decodeObject(forKey: "notes") as! SKNode
        stave = aDecoder.decodeObject(forKey: "stave") as! Stave

        touchNotePairs = aDecoder.decodeObject(forKey: "touchNotePairs") as! [UITouch : SKNode]
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
            
            //Collection position of current note
            let notesPosition = note.position
            
            //See if the current node was touched.
            if positionsAreSameWithinThreshold(notesPosition, touchPosition!, note.size) {
                // connect the note to the finger for touches moved
                touchNotePairs[touch!] = note
                
                // check if taped two times, if so change state
                if (touch?.tapCount)! > 1 {
                    note.changeNormSharpFlat()
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
      
        
        //check if the touch was associated with a note
        if let note = touchNotePairs[touch!]{
            //there was a note, try to snap it to a bar or let it fall to bottom of screen
            snapOrDropNote(note: note)
        }
        
        //remove touch and note pair from dictionary
        touchNotePairs.removeValue(forKey: touch!) //first touch is guaranteed to not be nil
        
    }
    
    func snapOrDropNote(note:SKNode){
        
        //if there is a position to snap to, then do it!
        if let snapToPoint = stave.findSnapPositionOrNil(PointToCheck: note.position, CurrentStavePos: stave.position){
            let move = SKAction.move(to: snapToPoint, duration: 0.25)   //duration is in seconds
            note.run(move)
            
        } else {
            //there is no snap position, let the note slowly fall to the bottom of the screen.
            //TODO implement this
        }
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches{
            if let note = touchNotePairs[touch] {
                note.position = touch.location(in: notes) //may be a coordinate conversion issue
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
}
