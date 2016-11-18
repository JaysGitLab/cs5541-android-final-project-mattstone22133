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
