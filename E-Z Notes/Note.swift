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
    static let redTexture = SKTexture(imageNamed: "ez_note_red_30x30_label.png")
    static let blueTexture = SKTexture(imageNamed: "ez_note_blue_30x30_label.png")
    static let blackTexture = SKTexture(imageNamed: "ez_note_30x30.png")
    static let aTexture = SKTexture(imageNamed: "A.png")
    static let bTexture = SKTexture(imageNamed: "B.png")
    static let cTexture = SKTexture(imageNamed: "C.png")
    static let dTexture = SKTexture(imageNamed: "D.png")
    static let eTexture = SKTexture(imageNamed: "E.png")
    static let fTexture = SKTexture(imageNamed: "F.png")
    static let gTexture = SKTexture(imageNamed: "G.png")
    static let twoTexture = SKTexture(imageNamed: "2.png")
    static let threeTexture = SKTexture(imageNamed: "3.png")
    static let fourTexture = SKTexture(imageNamed: "4.png")
    static let fiveTexture = SKTexture(imageNamed: "5.png")
    
    //children nodes
    var noteLabelSprite = SKSpriteNode(texture: eTexture)
    var noteOctaveSprite = SKSpriteNode(texture: twoTexture)
    
    
    //fields/properties
    var normal:Bool = true
    var sharp:Bool = false
    var flat:Bool = false
    var representsNote:NoteEnum? = nil //nil values signal that note is not correctly placed
    var representsOctave:OctaveEnum? = nil  //nil value signal invalid octave
    
    var showLabel = true
    
    
    init(imageNamed:String){ //TODO instead of adding noteLabel on every updateNote call, do it here.
        super.init(texture: Note.blackTexture, color: SKColor.clear, size: Note.blackTexture.size())
        addChild(noteLabelSprite)
        addChild(noteOctaveSprite)
        setUpLabels()
    }
    
    func setUpLabels(){
        noteLabelSprite.zPosition = 2.5
        noteOctaveSprite.zPosition = 2.5
        
        noteLabelSprite.isHidden = true
        noteOctaveSprite.isHidden = true
    }
    
    
    init(){
        super.init(texture: Note.blackTexture, color: SKColor.clear, size: Note.blackTexture.size())
        addChild(noteLabelSprite)
        addChild(noteOctaveSprite)
        setUpLabels()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func updateNote(NotesUpdatedPoint futurePnt:CGPoint, StavePositionInView stavePos: CGPoint, Stave stave:Stave){
        if showLabel {
            if representsNote != nil && representsOctave != nil && !sharp && !flat {
                unHideSubSprites()
                setOctaveNumberText()
                setNoteLetterText()
            } else {
                //if it is not a valid note, do not show labels.
                hideSubSprites()
            }
            
        }
    }
    
    func setOctaveNumberText(){
        if let validNote = self.representsOctave{
            switch validNote {
            case OctaveEnum.two:
                noteOctaveSprite.texture = Note.twoTexture
            case OctaveEnum.three:
                noteOctaveSprite.texture = Note.threeTexture
            case OctaveEnum.four:
                noteOctaveSprite.texture = Note.fourTexture
            case OctaveEnum.five:
                noteOctaveSprite.texture = Note.fiveTexture
            default:
                print("default in setOctaveNumberText; this should not ever be called - investigate code.")
            }
            noteLabelSprite.texture = Note.gTexture;
        }
    }
    
    func setNoteLetterText(){
        if let validNote = self.representsNote {
            switch validNote {
            case NoteEnum.E:
                noteLabelSprite.texture = Note.eTexture
            case NoteEnum.F:
                noteLabelSprite.texture = Note.fTexture
            case NoteEnum.G:
                noteLabelSprite.texture = Note.gTexture
            case NoteEnum.A:
                noteLabelSprite.texture = Note.aTexture
            case NoteEnum.B:
                noteLabelSprite.texture = Note.bTexture
            case NoteEnum.C:
                noteLabelSprite.texture = Note.cTexture
            case NoteEnum.D:
                noteLabelSprite.texture = Note.dTexture
            default:
                //logic in update note will hide note label, so it is NOT done here.
                print("default in setNoteLetterText; this should not ever be called - investigate code.")
            }
        }
    }
    
    func unHideSubSprites(){
        noteLabelSprite.isHidden = false
        noteOctaveSprite.isHidden = false
    }
    
    func hideSubSprites(){
        noteLabelSprite.isHidden = true
        noteOctaveSprite.isHidden = true
    }
    
    func scaleSubSpriteToFitInNote(Sprite sprite:SKSpriteNode){
        //only scale if the sub-sprite is larger
        if (self.size.width < sprite.size.width) {
            let xScaleFactor = (self.size.width / sprite.size.width) * 0.5
            sprite.setScale(xScaleFactor)
        }
    }
    
    //note: all internal transformations must be done before scale is applied to the entire note.
    //calling self.setScale will scale not only the note image, but all sub-nodes also; thus,
    //the calls to set up the internal child/sub-nodes occur before the self.setScale()
    func customScale(ScaleFactor scaleFactor:CGFloat){
        scaleSubSpriteToFitInNote(Sprite: noteLabelSprite)
        scaleSubSpriteToFitInNote(Sprite: noteOctaveSprite)
        positionSubSprites()
        
        self.setScale(scaleFactor)
    }
    
    func positionSubSprites(){
        //offset the note letter and octave number by a percentage of the note's width.
        let offset:CGFloat = self.size.width * 0.15
        
        //The center of the note is at 0,0; which is why zeros are used in the two statements below.
        noteOctaveSprite.position = CGPoint(x: 0 + offset, y: 0)
        noteLabelSprite.position = CGPoint(x: 0 - offset, y: 0)
        
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
