//
//  Lock.swift
//  E-Z Notes
//
//  Created by Matt Stone on 12/4/16.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import UIKit
import SpriteKit


class Lock: SKNode {
    static let lockedTexture = SKTexture(imageNamed: "Locked500x500.png")
    static let unlockedTexture = SKTexture(imageNamed: "unLocked500x500.png")
    var locked:Bool = false
    var lockSprite = SKSpriteNode(imageNamed: "unLocked500x500.png")
    
    override init(){
        super.init()
        self.addChild(lockSprite)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func isLocked() -> Bool{
        return locked
    }

    func lock(){
        locked = true
        lockSprite.texture = Lock.lockedTexture
    }
    
    func unlock(){
        locked = false
        lockSprite.texture = Lock.unlockedTexture
    }
    
    func setLocked(value:Bool){
        if value {
            lock()
        } else {
            unlock()
        }
    }
    
    func toggle(){
        setLocked(value: !locked)
    }
    
    func getScaledSize() -> CGSize {
        let sizeReduceFactor:CGFloat = 0.5
        let scaledSize = CGSize(width: lockSprite.size.width * self.xScale * sizeReduceFactor,
                                height: lockSprite.size.height * self.yScale * sizeReduceFactor)
        return scaledSize
    }
    func getUnscaledSize() -> CGSize{
        return lockSprite.size
    }
}
