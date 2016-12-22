//
//  KeyboardTouchableKey.swift
//  E-Z Notes
//
//  Created by Matt Stone on 12/21/16.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import UIKit
import SpriteKit

class KeyboardTouchableKey: SKSpriteNode {
    public var keyNumber:NoteEnum? = nil
    public var octaveNumber:OctaveEnum? = nil
    
    func playNote(){
        //if the key has a valid internal set up
        if keyNumber != nil && octaveNumber != nil {
            if let noteTuple = keyNumber?.toStringTuple(){
                let noteSoundFileStr = "Sounds/"
                    + noteTuple.0
                    + octaveNumber!.toString()
                    + noteTuple.1
                    + ".wav"
                run(SKAction.playSoundFileNamed(noteSoundFileStr, waitForCompletion: false))
            } else {
                print("\n\nFAILED TO LOAD SOUND\n\n")
            }
        }
    }
}
