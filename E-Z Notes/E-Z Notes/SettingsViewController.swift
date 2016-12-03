//
//  SettingsViewController.swift
//  E-Z Notes
//
//  Created by Matt Stone on 11/30/16.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {


    @IBOutlet weak var showLettersOnNotesSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //get the singleton
        if let singleton:EZNoteScene = GlobalSpace.ezscene{
            showLettersOnNotesSwitch.isOn = singleton.showNoteLetters
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let singleton:EZNoteScene = GlobalSpace.ezscene{
            singleton.setShowNotes(ShowNoteLetters: showLettersOnNotesSwitch.isOn)
        }
    }
    
    //Picker Interfaces(delgates)
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1;
    }
    
    func pickerView(_ pickerView: UIPickerView,
                    numberOfRowsInComponent component: Int) -> Int{
        return 1
    }

    func pickerView(_ pickerView: UIPickerView,
                    titleForRow row: Int,
                    forComponent component: Int) -> String? {
        return "test"
    }
    

}
