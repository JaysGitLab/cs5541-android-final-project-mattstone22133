//
//  Stave.swift
//  E-Z Notes
//
//  Created by Matt Stone on 11/8/16.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import UIKit
import SpriteKit

class Stave: SKNode {
    var barContainer:SKNode = SKNode()
    var screenHeight:CGFloat
    var screenWidth:CGFloat
    var numberOfBars = 26   //this number includes hidden bars
    var noteSpacing:CGFloat{
        get{
            //since logic behind note spacing is frequently changed, this getter is provided.
            //modify this getter so that noteSpacing logic is propogated throughout class.
            return screenHeight * 0.6 / CGFloat(numberOfBars)
        }
    }
    
    init(Height height:CGFloat, Width width:CGFloat){
        self.screenHeight = height
        self.screenWidth = width
        super.init()
        addChild(barContainer)
        buildBarsBottomUp()
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        //frameSize = aDecoder.decodeObject(forKey: "frameSize") as! CGSize //EXAMPLE
        screenHeight = aDecoder.decodeObject(forKey: "screenHeight") as! CGFloat
        screenWidth = aDecoder.decodeObject(forKey: "screenWidth") as! CGFloat
        super.init(coder: aDecoder) //called after this object has be inits fields
    }
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder) //called before this object encodes any fields
        aCoder.encode(screenHeight, forKey: "screenHeight")
        aCoder.encode(screenWidth, forKey: "screenWidth")
        //aCoder.encode(frameSize, forKey:"frameSize") //EXAMPLE
    }
    
    func buildBarsBottomUp(){
        let noteSpacing = self.noteSpacing  //avoid recalculation overhead by saving in local variable
        for i in 0..<numberOfBars {
            let tempSprite = BarSprite(sizeBarNeedsToCover: screenWidth)
            tempSprite.position = CGPoint(x: 0, y: noteSpacing * CGFloat(i))
            barContainer.addChild(tempSprite)
            //update note values?
            
            //hide odd bars (or the very middle bar)
            if (i % 2 == 1 || barShouldBeHidden(barNumber: i)){
                tempSprite.setHidden(Hidden: true)
            }
        }
    }
    
    //function checks the value of a barNumber to determine if it is a special bar and should be hidden
    func barShouldBeHidden(barNumber:Int) -> Bool{
        let middleBar:Int = 12
        let hiddenBottonBar:Int = 0
        let hiddenTopBar:Int = 24
        
        return (barNumber == middleBar
            || barNumber == hiddenBottonBar
            || barNumber == hiddenTopBar)
        
    }
    
    func getHalfBarDistance() -> CGFloat{
        //return calculateNoteSpacing()
        return noteSpacing
    }
    
    func findSnapPositionOrNil(PointToCheck testPoint:CGPoint) -> CGPoint?{
        let testPoint = CGPoint(x: 300, y: 300)
        
        for bar in barContainer.children {
            
        }
        
        
        return testPoint
    }
}
