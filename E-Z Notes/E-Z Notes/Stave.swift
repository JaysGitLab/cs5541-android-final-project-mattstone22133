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
    var topBar:SKNode = SKNode()
    var bar2:SKNode = SKNode()
    var bar3:SKNode = SKNode()
    var bar4:SKNode = SKNode()
    var bottomBar: SKNode = SKNode()
    
    
    override init(){
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
   
}
