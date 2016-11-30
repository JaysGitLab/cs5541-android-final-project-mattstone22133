//
//  Note.swift
//  E-Z Notes
//
//  Created by Matt Stone on 11/15/16.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import UIKit
import SpriteKit

class Note: SKSpriteNode {
    //textures are static to prevent redundantly creating the same textures for each note
    static let redTexture = SKTexture(imageNamed: "ez_note_red_30x30.png")
    static let blueTexture = SKTexture(imageNamed: "ez_note_blue_30x30.png")
    static let blackTexture = SKTexture(imageNamed: "ez_note_30x30.png")
    
    //fields/properties
    var normal:Bool = true
    var sharp:Bool = false
    var flat:Bool = false
    var representsNote:NoteEnum? = nil //nil values signal that note is not correctly placed
    var representsOctave:OctaveEnum? = nil  //nil value signal invalid octave
    var showLabel = true
    var noteLabel:SKLabelNode = SKLabelNode(fontNamed: "Courier-Bold")
    var noteLabelCorrectlyPositionedAfterScale = false  //since scaling occurs after construction, we must handle scaling this way
    
    init(imageNamed:String){ //TODO instead of adding noteLabel on every updateNote call, do it here.
        super.init(texture: Note.blackTexture, color: SKColor.clear, size: Note.blackTexture.size())
        addChild(noteLabel) //since the init was not overridden, this is called here TODO
        setUpLabel()
    }
    
    func setUpLabel(){
        noteLabel.zPosition = 1.5   //draw on top of note
    }
    
    init(){
        super.init(texture: Note.blackTexture, color: SKColor.clear, size: Note.blackTexture.size())
        addChild(noteLabel) //since the init was not overridden, this is called here TODO
        setUpLabel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented") //TODO implement this properly
    }
    
    func updateNote(NotesUpdatedPoint futurePnt:CGPoint, StavePositionInView stavePos: CGPoint, Stave stave:Stave){
        if showLabel {
            if representsNote != nil && representsOctave != nil && !sharp && !flat {
                let noteStr = representsNote!.toStringTuple().0 + representsOctave!.toString()
                noteLabel.text = noteStr
                noteLabel.xScale = self.xScale
                noteLabel.yScale = self.yScale
                updateLabelPosition()
            } else {
                //if it is not a valid note, do not show a (old) label.
                noteLabel.text = ""
            }
            
        }
    }
    
    func updateLabelPosition(){
        if !noteLabelCorrectlyPositionedAfterScale {
            //move the label
            let rawPos = noteLabel.position
            //center the font inside of the note
            noteLabel.position = CGPoint(x:rawPos.x, y: rawPos.y - self.size.height * 2/5) //SHOULD ONLY BE CALLED ONCE, move to init
            noteLabelCorrectlyPositionedAfterScale = true
        }
    }
    
    func changeNormSharpFlat(){
        if normal {
            normal = false
            sharp = true
            //change color to red (sharps are red)
            self.texture = Note.redTexture
            
        } else if sharp {
            sharp = false
            flat = true
            //change color to blue (flats are blue)
            self.texture = Note.blueTexture
            
        } else {
            //flat
            flat = false
            normal = true
            //change color to black
            self.texture = Note.blackTexture
        }
    }
    
    func playNote(){
        if let noteTuple = representsNote?.toStringTuple(){
            let noteSoundFileStr = "Sounds/"
                + noteTuple.0
                + representsOctave!.toString()
                + noteTuple.1
                + ".wav"
            run(SKAction.playSoundFileNamed(noteSoundFileStr, waitForCompletion: false))
        } else {
            print("\n\nFAILED TO LOAD SOUND\n\n")
        }
    }
}
