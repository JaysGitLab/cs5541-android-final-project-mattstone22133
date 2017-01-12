//
//  KeyboardButton.swift
//  E-Z Notes
//
//  Created by Matt Stone on 1/11/17.
//  Copyright © 2017 Matt Stone. All rights reserved.
//

import UIKit
import SpriteKit

class KeyboardButton: SKSpriteNode {
    private(set) var toggle:Bool = false;
    
    public func changeState(){// -> Bool{
        toggle = !toggle;
        //return toggle;
    }
    
    public func touched(point:CGPoint) -> Bool{
        return touchCollisionWithSprite(TouchLocation: point, SpriteObj: self)
    }
    
    private func touchCollisionWithSprite(TouchLocation touchLocation: CGPoint, SpriteObj sprite:SKSpriteNode) -> Bool {
        
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
}
