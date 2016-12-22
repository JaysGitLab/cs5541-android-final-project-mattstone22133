//
//  Keyboard.swift
//  E-Z Notes
//
//  Created by Matt Stone on 12/19/16.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import UIKit
import SpriteKit

class Keyboard: SKNode {
    private var whiteKeys:SKNode = SKNode()
    private var blackKeys:SKNode = SKNode()
    private var screenSize:CGSize? = nil
    
    //default values below are changed in method calls.
    private var totalNumberWhiteKeys = -1
    private var startOctave = -1
    
    public static var numberWhiteKeys = 7
    
    init(frameSize:CGSize){
        super.init()
        
        //save a copy of the frameSize
        self.screenSize = CGSize(width: frameSize.width, height: frameSize.height)

        
        addChild(whiteKeys)
        addChild(blackKeys)
        
        
        createWhiteKeys()
        createBlackKeys()
        
        centerKeyboardPosition()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func createWhiteKeys(){
        //create a variable that can be changed
        totalNumberWhiteKeys = 14
        startOctave = 4
        
        //set up whiteKeys
        for i in 1...totalNumberWhiteKeys{
            //create key
            let newKey = KeyboardTouchableKey(imageNamed: "PianoWhiteKeysSquare100x100.png")
            
            //scale key width (total width = 3/4 of screen size)
            let threeQuarterScreen = screenSize!.width * 0.75
            let newNoteWidth = threeQuarterScreen / CGFloat(totalNumberWhiteKeys)
            let widthScaleFactor = newNoteWidth / newKey.size.width
            newKey.xScale = widthScaleFactor
            
            //scale key height (total height = 2*scaledWidth)
            let targetHeight = screenSize!.height * 0.15 //2 * newKey.size.width
            let scaleFactor = targetHeight / newKey.size.height
            newKey.yScale = scaleFactor
            
            //position key internally
            newKey.position.x += newKey.size.width * CGFloat(i)
            
            //update the key field values
            newKey.keyNumber = NoteEnum.getWhiteKeyNoteIndexStartAtC(rawValueStartC: (i - 1) % 7)
            let octave = startOctave + ((i - 1) / Keyboard.numberWhiteKeys)
            newKey.octaveNumber = OctaveEnum(rawValue: octave - OctaveEnum.startingNumber)
            
            //add key reference to containers
            whiteKeys.addChild(newKey)
        }
    }
    
    //invariant 1: total number of keys has already been set
    //invariant 2: at least one white key has been made (used to determine scaling)
    func createBlackKeys(){
        //Loop through white keys adding black keys as necesarry
        for key in whiteKeys.children as! [KeyboardTouchableKey] {
            
            //nil check for remaining logic, if nil then continue to prevent crash
            if(key.keyNumber == nil){
                continue
            }
            
            switch(key.keyNumber!){
            case NoteEnum.C: fallthrough
            case NoteEnum.D: fallthrough
            case NoteEnum.F: fallthrough
            case NoteEnum.G: fallthrough
            case NoteEnum.A:
                let newBlackKey = configureBlackKeyForWhiteKey(WhiteKey: key)
                blackKeys.addChild(newBlackKey)
                break;
            default:
                //do nothing
                break;
            }
 
        }
        
    }
    
    //invariant 1: keyNumber is not nil for the parameter key
    func configureBlackKeyForWhiteKey(WhiteKey key:KeyboardTouchableKey) -> KeyboardTouchableKey{
        let newBlackKey = KeyboardTouchableKey(imageNamed: "PianoBlackKeysSquare100x100.png")
        newBlackKey.xScale = key.xScale * 0.70
        newBlackKey.yScale = key.yScale * 0.60
        
        //change z position to a value higher than white keys, that way black keys are drawn on top
        newBlackKey.zPosition = key.zPosition + 0.1
        //position the black key at the point between the current white key and the white key to the right
        newBlackKey.position.x = key.position.x + key.size.width / 2
        //position its height so that it starts at the top of the white key
        newBlackKey.position.y = key.position.y + key.size.height / 2 - (newBlackKey.size.height / 2)
        
        //update key fields
        newBlackKey.keyNumber = NoteEnum.getSharpNote(note: key.keyNumber!)
        newBlackKey.octaveNumber = key.octaveNumber
        
        //add key to the children so it will be drawn
        return newBlackKey
    }
    
    //invariant: keyboard must be in a position where the first key starts at 0,0
    //(this is how the generation alogrithm produces keys)
    func centerKeyboardPosition(){
        //calculate distance to shift left: (half the entire distance the keyboard spans)
        let keyUsedForMeasurements = whiteKeys.children[0] as! SKSpriteNode
        let moveHorizontalDistance = (CGFloat(totalNumberWhiteKeys) * keyUsedForMeasurements.size.width) / 2
            + keyUsedForMeasurements.size.width / 2 // add in a half of note
        let moveVertically = (keyUsedForMeasurements.size.height) / 2
        
        //shift white keys
        for key:SKSpriteNode in whiteKeys.children as! [SKSpriteNode] {
            //horrozontal distance
            let keyPosition = key.position.x
            key.position.x = keyPosition - moveHorizontalDistance
            
            //vertical distance (move keys 1/2 scaled height upward; note: key already position at 1/2 mark)
            //let moveVertically = key.size.height / 2
            key.position.y = key.position.y + moveVertically
        }
        
        //shift black keys
        for key:SKSpriteNode in blackKeys.children as! [SKSpriteNode]{
            //horrozontal distance
            key.position.x = key.position.x - moveHorizontalDistance
            //vertical distance (move keys 1/2 scaled height upward; note: key already position at 1/2 mark)
            key.position.y = key.position.y + moveVertically
        }
    }
    
    //returns x location of key, note of key, and octave of key
    func pollKeyTouched(touch: UITouch) -> (CGFloat, NoteEnum?, OctaveEnum?)?{
        let touchLocation = touch.location(in: self)
        
        //check black keys (must be checked first since they're also in the range of the white keys
        for key in blackKeys.children as! [KeyboardTouchableKey]{
            if (touchCollisionWithKey(TouchLocation: touchLocation, KeyObj: key)){
                key.playNote()
                return (calculateTrueXPosition(key: key), key.keyNumber, key.octaveNumber)
            }
        }
        
        //check white keys
        for key in whiteKeys.children as! [KeyboardTouchableKey]{
            if (touchCollisionWithKey(TouchLocation: touchLocation, KeyObj: key)){
                key.playNote()
                return (calculateTrueXPosition(key: key), key.keyNumber, key.octaveNumber)
            }
        }
        
        //no collision was found, return nil
        return nil
    }
    
    func touchCollisionWithKey(TouchLocation touchLocation: CGPoint, KeyObj key:KeyboardTouchableKey) -> Bool {
        let minX = key.position.x - (key.size.width / 2)
        let maxX = key.position.x + (key.size.width / 2)
        
        let minY = key.position.y - (key.size.height / 2)
        let maxY = key.position.y + (key.size.height / 2)
        
        //check x range
        if (touchLocation.x >= minX && touchLocation.x <= maxX) {
            //check y range
            if (touchLocation.y >= minY && touchLocation.y <= maxY){
                return true
            }
        }
        return false
    }
    
    func calculateTrueXPosition(key:KeyboardTouchableKey) -> CGFloat{
        return key.position.x + self.position.x
    }

}
