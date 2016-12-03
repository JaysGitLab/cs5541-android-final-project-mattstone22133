//
//  GameViewController.swift
//  E-Z Notes
//
//  Created by Matt Stone on 11/3/16.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
    
    @IBOutlet weak var SettingsButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let view = self.view as! SKView
        
        let scene = EZNoteScene(Framesize: view.frame.size)
        scene.scaleMode = .resizeFill
        view.ignoresSiblingOrder = true
        
        view.showsFPS = true
        view.showsNodeCount = true
        view.presentScene(scene)
        
    }
    
    @IBAction func unwindToMenu(segue: UIStoryboardSegue) {}
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            //return .allButUpsideDown
            return UIInterfaceOrientationMask.landscape
        }else {
            return .landscape //TODO test w/ ipad simulator
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
