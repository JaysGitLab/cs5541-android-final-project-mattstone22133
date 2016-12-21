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
    private var totalNumberWhiteKeys = 14
    
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
        totalNumberWhiteKeys = 7
        
        //set up whiteKeys
        for i in 1...totalNumberWhiteKeys{
            //create key
            var newKey = SKSpriteNode(imageNamed: "PianoWhiteKeysSquare100x100.png")
            
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
            
            //add key reference to containers
            whiteKeys.addChild(newKey)
        }
    }
    
    //invariant: total number of keys has already been set
    func createBlackKeys(){
        //This methods requries that the total number of keys already be set, do not modify total number of keys in ths method
        
        //variable to represent number of white keys (this can be used to calculate position of the black keys)
        let numberOfUniqueWhiteKeys = 7
        
        //Loop through white keys adding black keys as necesarry
        for i in 0..<(totalNumberWhiteKeys){
            //check if csharp
            if i % numberOfUniqueWhiteKeys == 0 {
                
            }
            
            //check if dsharp 
            if i % numberOfUniqueWhiteKeys == 1 {
                
            }
            
            //check if fsharp
            if i % numberOfUniqueWhiteKeys == 3 {
                
            }
            
            //check if gsharp
            if i % numberOfUniqueWhiteKeys == 4 {
                
            }
            
            //check if asharp
            if i % numberOfUniqueWhiteKeys == 5 {
                
            }
        }
        
    }
    
    func centerKeyboardPosition(){
        //calculate distance to shift left: (half the entire distance the keyboard spans)
        let moveHorizontalDistance = (CGFloat(totalNumberWhiteKeys) * (whiteKeys.children[0] as! SKSpriteNode).size.width) / 2
        
        //shift white keys
        for key:SKSpriteNode in whiteKeys.children as! [SKSpriteNode] {
            //horrozontal distance
            let keyPosition = key.position.x
            key.position.x = keyPosition - moveHorizontalDistance
            
            //vertical distance (move keys 1/2 scaled height upward; note: key already position at 1/2 mark)
            let moveVertically = key.size.height / 2
            key.position.y = key.position.y + moveVertically
        }
        
        
        //shift black keys
    }

}
