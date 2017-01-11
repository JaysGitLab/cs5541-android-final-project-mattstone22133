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
    //static/class fields
    public static var numberWhiteKeys = 7
    
    //instance fields
    //normal key containers
    private var whiteKeys:SKNode = SKNode()
    private var blackKeys:SKNode = SKNode()
    
    //highlight variables
    private var yellowTouchKeys:SKNode = SKNode()
    private var numberOfYellowHighlightKeys = 5
    private var nextYellowKeyIndex = 0
    private var yellowKeyFadeTime = 1.0
    
    private var screenSize:CGSize? = nil
    
    //octave variables
    private var rightButton:SKSpriteNode = SKSpriteNode(imageNamed: "EZ-NoteRight100x100.png")
    private var leftButton:SKSpriteNode = SKSpriteNode(imageNamed: "EZ-NoteLeft100x100.png")

    
    //default values below are changed in method calls.
    private var totalNumberWhiteKeys = -1
    private var startOctave = -1
    private var lastKey:KeyboardTouchableKey? = nil
    
    init(frameSize:CGSize){
        super.init()
        
        //save a copy of the frameSize
        self.screenSize = CGSize(width: frameSize.width, height: frameSize.height)

        
        addChild(whiteKeys)
        addChild(blackKeys)
        addChild(yellowTouchKeys)
        addChild(rightButton)
        addChild(leftButton)
        
        
        createWhiteKeys()
        createBlackKeys()
        createYellowKeysForHighlighting()
        setUpOctaveButtons()
        
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
    
    
    func createYellowKeysForHighlighting(){
        for _ in 0...numberOfYellowHighlightKeys {
            //create the key and change its alpha so that it is invisible
            let newKey = KeyboardTouchableKey(imageNamed: "PianoYellowKeysSquare100x100.png")
            newKey.alpha = 0.0
            
            yellowTouchKeys.addChild(newKey)
        }
    }

    func getYellowKeyReference() -> KeyboardTouchableKey {
        //get reference at current index
        let ref = (yellowTouchKeys.children as! [KeyboardTouchableKey])[nextYellowKeyIndex]
        
        //add 1 to index, if it is at the maximum capacity then take it back to zero
        nextYellowKeyIndex = (nextYellowKeyIndex + 1 ) % yellowTouchKeys.children.count
        
        return ref
    }
    
    
    //invariant 1: keyNumber is not nil for the parameter key
    func configureBlackKeyForWhiteKey(WhiteKey key:KeyboardTouchableKey) -> KeyboardTouchableKey{
        let newBlackKey = KeyboardTouchableKey(imageNamed: "PianoBlackKeysSquare100x100.png")
        newBlackKey.xScale = key.xScale * 0.70
        newBlackKey.yScale = key.yScale * 0.60
        
        //change z position to a value higher than white keys, that way black keys are drawn on top
        newBlackKey.zPosition = key.zPosition + 0.5
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
    
    //invariant1: white keys have already be initialized and sized
    //invariant2: right and left button images are exactly the same dimensions
    func setUpOctaveButtons() {
        let keyRef = (whiteKeys.children as! [SKSpriteNode])[0]
        
        //draw buttons on top (helps with debugging/development testing)
        rightButton.zPosition = keyRef.zPosition + 0.1
        leftButton.zPosition = keyRef.zPosition + 0.1

        
        //scale buttons so that they're 2x the width of a white key.
        let keyWidth = keyRef.size.width
        let xScaleFactor = (keyWidth) / (rightButton.size.width * rightButton.xScale)

        rightButton.xScale = xScaleFactor
        leftButton.xScale = xScaleFactor
        
        //scale buttons so they are they height of a white key
        let keyHeight = keyRef.size.height
        let yScaleFactor =  keyHeight / (rightButton.size.height * rightButton.yScale)

        rightButton.yScale = yScaleFactor
        leftButton.yScale = yScaleFactor
        
        //these functions below can be used if keyboard size is changed
        positionRightButton()
        positionLeftButton()
    }
    
    func positionRightButton(){
        //right button shoudl be at the right-most position next to a white key 
        let numberOfWhiteKeys = whiteKeys.children.count
        let rightMostWhiteKey = (whiteKeys.children as! [SKSpriteNode])[numberOfWhiteKeys - 1]
        
        //position button 1.5 white key's distances over
        rightButton.position.x = rightMostWhiteKey.position.x
        rightButton.position.x += 1.5 * rightMostWhiteKey.size.width// + 0.5 * rightMostWhiteKey.size.width
    }
    
    func positionLeftButton(){
        //left button should be at the left-most position next to a whiteKey
        let leftMostWhiteKey = (whiteKeys.children as! [SKSpriteNode])[0]
        
        //position button 1.5 white key's distances over
        leftButton.position.x = leftMostWhiteKey.position.x
        leftButton.position.x -= 1.5 * leftMostWhiteKey.size.width
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
        
        //shift buttons
        rightButton.position.x -= moveHorizontalDistance
        rightButton.position.y += moveVertically
        leftButton.position.x -= moveHorizontalDistance
        leftButton.position.y += moveVertically

    }
    
    //returns x location of key, note of key, and octave of key
    func pollKeyTouched(touch: UITouch) -> (CGFloat, NoteEnum?, OctaveEnum?)?{
        let touchLocation = touch.location(in: self)
        
        //check black keys (must be checked first since they're also in the range of the white keys
        for key in blackKeys.children as! [KeyboardTouchableKey]{
            if (touchCollisionWithKey(TouchLocation: touchLocation, KeyObj: key)){
                key.playNote()
                playKey(key: key)
                lastKey = key
                return (calculateTrueXPosition(key: key), key.keyNumber, key.octaveNumber)
            }
        }
        
        //check white keys
        for key in whiteKeys.children as! [KeyboardTouchableKey]{
            if (touchCollisionWithKey(TouchLocation: touchLocation, KeyObj: key)){
                //key.playNote()
                playKey(key: key)
                lastKey = key
                return (calculateTrueXPosition(key: key), key.keyNumber, key.octaveNumber)
            }
        }
        
        //no collision was found, return nil
        return nil
    }
    
    //returns x location of key, note of key, and octave of key
    func pollDifferentKeyTouched(touch: UITouch) -> (CGFloat, NoteEnum?, OctaveEnum?)?{
        if(lastKey == nil){
            return nil
        }
        
        let touchLocation = touch.location(in: self)
        
        //check black keys (must be checked first since they're also in the range of the white keys
        for key in blackKeys.children as! [KeyboardTouchableKey]{
            if (touchCollisionWithKey(TouchLocation: touchLocation, KeyObj: key)){
                if(key != lastKey){
                    key.playNote()
                    playKey(key: key)
                    lastKey = key
                    return (calculateTrueXPosition(key: key), key.keyNumber, key.octaveNumber)
                } else {
                    return nil
                }
            }
        }
        
        //check white keys
        for key in whiteKeys.children as! [KeyboardTouchableKey]{
            if (touchCollisionWithKey(TouchLocation: touchLocation, KeyObj: key)){
                if(key != lastKey){
                    key.playNote()
                    playKey(key: key)
                    lastKey = key
                    return (calculateTrueXPosition(key: key), key.keyNumber, key.octaveNumber)
                } else {
                    return nil
                }
            }
        }
        
        //no collision was found, return nil
        return nil
    }
    
    func playKey(key:KeyboardTouchableKey){
        //play the sound associated with the key
        key.playNote()
        
        //highlight the key on the piano
        let highlight = getYellowKeyReference()
        highlight.removeAllActions()
        highlight.position = key.position
        highlight.xScale = key.xScale
        highlight.yScale = key.yScale
        highlight.alpha = 1.0
        highlight.zPosition = key.zPosition + 0.1
        let fade = SKAction.fadeAlpha(to: 0.0, duration: yellowKeyFadeTime)
        highlight.run(fade)
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
    
    func touchCollisionWithSprite(TouchLocation touchLocation: CGPoint, SpriteObj sprite:SKSpriteNode) -> Bool {
        let minX = sprite.position.x - (sprite.size.width / 2)
        let maxX = sprite.position.x + (sprite.size.width / 2)
        
        let minY = sprite.position.y - (sprite.size.height / 2)
        let maxY = sprite.position.y + (sprite.size.height / 2)
        
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
    
    func pollOctaveButtonPressedAndHandle(touch: UITouch) -> Bool{
        //convert the touch to the keyboards internal coordinate system
        let touchLocation = touch.location(in: self)
        
        //check right button
        if(touchCollisionWithSprite(TouchLocation: touchLocation, SpriteObj: rightButton)){
            if shiftOctavesUp(){
                makeSpriteFadeTo100(sprite: rightButton)
                return true
            }
        }else if (touchCollisionWithSprite(TouchLocation: touchLocation, SpriteObj: leftButton)){
            if shiftOctavesDown(){
                makeSpriteFadeTo100(sprite: leftButton)
                return true
            }
        }
        return false
    }

    //invariant: all keys must have a valid octave number or this will crash will nil pointer
    func shiftOctavesDown() -> Bool{
        //ensure that lowest note can go an octave lower
        let keyRef = (whiteKeys.children as! [KeyboardTouchableKey])[0]
        let testOct = keyRef.octaveNumber!.attemptGetLower()
        if (testOct.rawValue == keyRef.octaveNumber!.rawValue){
            //return if the lowering of the octave produced the same octave
            return false
        }
        
        for key in whiteKeys.children as! [KeyboardTouchableKey]{
            let currOct = key.octaveNumber
            key.octaveNumber = currOct!.attemptGetLower()
        }
        for key in blackKeys.children as! [KeyboardTouchableKey]{
            let currOct = key.octaveNumber
            key.octaveNumber = currOct!.attemptGetLower()
        }
        return true
    }
    func shiftOctavesUp() -> Bool{
        //ensure that highest note can go an octave higher
        let lastKeyIndex = whiteKeys.children.count - 1
        let keyRef = (whiteKeys.children as! [KeyboardTouchableKey])[lastKeyIndex]
        let testOct = keyRef.octaveNumber!.attemptGetHigher()
        if (testOct.rawValue == keyRef.octaveNumber!.rawValue){
            //return if the raising of the octave produced the same octave
            return false
        }
        
        
        for key in whiteKeys.children as! [KeyboardTouchableKey]{
            let currOct = key.octaveNumber  //this should crash if the key's octave hasn't been set
            key.octaveNumber = currOct!.attemptGetHigher()
        }
        for key in blackKeys.children as! [KeyboardTouchableKey]{
            let currOct = key.octaveNumber  //this should crash if the key's octave hasn't been set
            key.octaveNumber = currOct!.attemptGetHigher()
        }
        return true
    }
    
    func makeSpriteFadeTo100(sprite:SKSpriteNode){
        sprite.removeAllActions()
        sprite.alpha = 0.0
        let fadeTo100 = SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        sprite.run(fadeTo100)
    }
}
