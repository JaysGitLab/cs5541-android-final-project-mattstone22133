//
//  SettingsViewController.swift
//  E-Z Notes
//
//  Created by Matt Stone on 11/30/16.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {


    @IBOutlet weak var doublePickerKeyScale: UIPickerView!
    @IBOutlet weak var showLettersOnNotesSwitch: UISwitch!
    let scaleTypes = ["Major", "Minor"]
    let scaleKeys = ["C", "C#", "Db", "D", "D#", "Eb", "E","F", "F#", "Gb","G", "G#", "Ab", "A","A#", "Bb", "B"]
    let typeIndex = 1
    let keyIndex = 0
    
    //Settings Menu Fields
    static var keyIndexForSettingMenu = 0
    static var styleIndexForSettingMenu = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //get the singleton
        if let singleton:EZNoteScene = GlobalSpace.ezscene{
            showLettersOnNotesSwitch.isOn = singleton.showNoteLetters
        }
        doublePickerKeyScale.selectRow(SettingsViewController.keyIndexForSettingMenu, inComponent: keyIndex, animated: false)
        doublePickerKeyScale.selectRow(SettingsViewController.styleIndexForSettingMenu, inComponent: typeIndex, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let singleton:EZNoteScene = GlobalSpace.ezscene{
            //Change preference in terms of showing notes
            singleton.setShowNotes(ShowNoteLetters: showLettersOnNotesSwitch.isOn)
            
            //Choosing scale
            //Below are static because settings menu is regenerated every time it is called
            SettingsViewController.keyIndexForSettingMenu = doublePickerKeyScale.selectedRow(inComponent: keyIndex)
            SettingsViewController.styleIndexForSettingMenu = (doublePickerKeyScale.selectedRow(inComponent: typeIndex))
            
            
            let keyString = scaleKeys[SettingsViewController.keyIndexForSettingMenu]
            let typeString = scaleTypes[SettingsViewController.styleIndexForSettingMenu]
            var typeChoice:Scale.Style
            if typeString == "Major"{
                typeChoice = Scale.Style.Major
            } else if typeString == "Minor" {
                typeChoice = Scale.Style.Minor
            } else {
                //default choice 
                typeChoice = Scale.Style.Major
            }
            singleton.targetScale?.setScaleBasedOnString(scale: keyString, Style: typeChoice)
            if(keyString.characters.count > 1){
                //get the character after the letter, and determine if it is # or b
                let index = keyString.index(keyString.startIndex, offsetBy: 1 )
                let typeChar = keyString[index]
                if(typeChar == "#"){
                    singleton.useModifications = Note.Pitch.Sharp
                } else {
                    singleton.useModifications = Note.Pitch.Flat
                }
            } else {
                singleton.useModifications = Note.Pitch.Normal
            }
        }
    }
    
    //Picker Interfaces(delgates)
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2;
    }
    
    func pickerView(_ pickerView: UIPickerView,
                    numberOfRowsInComponent component: Int) -> Int{
        if component == 0 {
           return scaleKeys.count
        } else {
            return scaleTypes.count
        }
    }

    func pickerView(_ pickerView: UIPickerView,
                    titleForRow row: Int,
                    forComponent component: Int) -> String? {
        if component == 0 {
            return scaleKeys[row]
        } else {
            return scaleTypes[row]
        }
    }
    

}
