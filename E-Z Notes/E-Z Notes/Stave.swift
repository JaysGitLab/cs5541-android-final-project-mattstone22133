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
    var screenHeight:CGFloat = 600  //this should be updated in init, this is set for testing purposes
    var screenWidth:CGFloat = 400   //TODO change this, it is set for debuggin purposes
    //let noteSpacing:CGFloat = 10.0  //adjust this to change distance between bars
    var numberOfBars = 26   //this number includes hidden bars
    
    
    init(Height height:CGFloat, Width width:CGFloat){
        super.init()
        self.screenHeight = height
        self.screenWidth = width
        addChild(barContainer)
        buildBarsBottomUp()
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        //frameSize = aDecoder.decodeObject(forKey: "frameSize") as! CGSize //EXAMPLE
        super.init(coder: aDecoder) //called after this object has be inits fields
    }
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder) //called before this object encodes any fields
        //aCoder.encode(frameSize, forKey:"frameSize") //EXAMPLE
    }
    
    func buildBarsBottomUp(){
        let noteSpacing = screenHeight * 0.6 / CGFloat(numberOfBars)
        
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
    
}
