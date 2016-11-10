//
//  BarSprite.swift
//  E-Z Notes
//
//  Created by Matt Stone on 11/8/16.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import UIKit
import SpriteKit

class BarSprite: SKNode {
    var containedSprites:SKNode = SKNode() //this is treated like an linked list container
    var numBarSegmentsNeeded:Int = 1
    var imageName:String = "ez_bar_2x100.png" //store this in plist? makes it easy to change after-fact.

    
    //This constructor should not be used.
    //instead use the constructo that specifies how large of a range the bar should cover.
    override init(){
        super.init()
        
        //set # bars needed to draw  (will be 1 for the no-arg)
        createBars()
        addChild(containedSprites)
    }
    
    init(sizeBarNeedsToCover sizeNeeded:CGFloat){
        super.init()
        
        //calculate how many bars will be needed to cover screen
        calculateNumberBarsNeededForSize(sizeNeeded: sizeNeeded)
        
        //set bars needed
        createBars()
        addChild(containedSprites)
    }
    
    required init?(coder aDecoder: NSCoder) {
        //frameSize = aDecoder.decodeObject(forKey: "frameSize") as! CGSize
        super.init(coder: aDecoder) //called after this object has be inits fields
    }

    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder) //called before this object encodes any fields
        //aCoder.encode(frameSize, forKey:"frameSize") //example
    }
    
    //Creates enough bar segments to cover the screen horrozontally.
    func createBars(){
        // loop (numBarSegmentsNeeded) times, add a bar segment and displace it based on i
        for i in 0..<numBarSegmentsNeeded {
            let tempSprite = SKSpriteNode(imageNamed: imageName)
            tempSprite.position = CGPoint(x: tempSprite.size.width * CGFloat(i), y: 0)
            containedSprites.addChild(tempSprite)
        }
    }
    
    //set the field numBarSegmentsNeeded to an integer representing how many bar sprites should be drawn to cover screen
    func calculateNumberBarsNeededForSize(sizeNeeded:CGFloat){
        //create a temporary sprite to extract its width programmatically.
        let tempSprite = SKSpriteNode(imageNamed: imageName) //wasteful, find way to get img width from file without object creation?
        
        //extract image width from the sprite size.
        let imageWidth = tempSprite.size.width
        
        //number of bar segments needed is how many times the bar image can fit in the view (ie do division)
        numBarSegmentsNeeded = Int(ceil(sizeNeeded / imageWidth) + 1)  //add 1 to account imperfect image size
    }
    
    //TODO: consider overriding the property setter and getter instead of using a raw function like this (override isHidden)
    func setHidden(Hidden hidden:Bool){
        for inode in (containedSprites.children) {
            inode.isHidden = hidden
        }
    }
}
