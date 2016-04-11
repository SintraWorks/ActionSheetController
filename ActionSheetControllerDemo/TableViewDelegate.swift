//
//  TableViewDelegate.swift
//  ActionSheetController
//
//  Created by Antonio Nunes on 14/03/16.
//  Copyright © 2016 SintraWorks. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit
import ActionSheetController
import AudioToolbox
import AVFoundation

@objc
class TableViewDelegate: NSObject {
    @IBOutlet var controller: UIViewController!
    
    var pickerViewDataSourceAndDelegate: UIPickerViewDelegate = PickerDataSourceAndDelegate()
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let rowIdentifier = self.rowIdentifierFromRowIndex(indexPath.row)
        
        var sheetController: ActionSheetController
        
        switch rowIdentifier {
        case .CustomView:
            sheetController = self.customSheet(.Light)
        case .BlackCustomView:
            sheetController = self.customSheet(.Dark)
        case .DatePickerView:
            sheetController = self.datePickerSheet()
        case .TransparentBackground:
            sheetController = self.transparentBackgroundSheet()
        case .NoBackgroundTaps:
            sheetController = self.noBackgroundTapsSheet()
        case .GroupedActions:
            sheetController = self.groupedActionsSheet()
        case .GroupedActionsBlack:
            sheetController = self.groupedActionsSheet(.Dark)
        }
        
        self.controller.presentViewController(sheetController, animated: true, completion: nil)
    }
}


extension TableViewDelegate {
    internal func rowIdentifierFromRowIndex(rowIndex: Int) -> RowIdentifier {
        guard let identifier = RowIdentifier(rawValue: rowIndex) else { fatalError("Invalid section") }
        return identifier
    }
}


extension TableViewDelegate {
    private func customSheet(style: ActionSheetControllerStyle) -> ActionSheetController {
        let cancelAction = ActionSheetControllerAction(style: .Cancel, title: "Cancel", dismissesActionController: true, handler: nil)
        let sheetController = ActionSheetController(style: style, title: "Hi there", message: "I'm a simple sheet boasting a custom view as my content view.", cancelAction: cancelAction, okAction: nil)

        let simpleView = CustomView(frame: CGRectZero)
        simpleView.translatesAutoresizingMaskIntoConstraints = false
        simpleView.heightAnchor.constraintEqualToConstant(100.0).active = true
        sheetController.contentView = simpleView
        
        return sheetController
    }


    private func datePickerSheet() -> ActionSheetController {
        let pickerView = UIDatePicker(frame: CGRectZero)

        let okAction = ActionSheetControllerAction(style: .Done, title: "OK", dismissesActionController: true) { controller in
            let date = pickerView.date
            let action = AlertAction(title: "Hurray!", style: .Default, enabled: true, isPreferredAction: true) {
                print("Dismissed!")
            }
            let alertInfo = AlertInfo(title: "Success", message: "You picked date: \(date.description)", actions: [action])
            QueuedAlertPresenter.sharedAlertPresenter.addAlert(alertInfo)
        }
        
        let cancelAction = ActionSheetControllerAction(style: .Cancel, title: "Cancel", dismissesActionController: true, handler: nil)
        let sheetController = ActionSheetController(title: "Date Picker", message: "Pick a date for your enjoyment…", cancelAction: cancelAction, okAction: okAction)
        
        sheetController.contentView = pickerView
        
        return sheetController
    }
    
    
    private func groupedActionsSheet(style: ActionSheetControllerStyle = .Light) -> ActionSheetController {
        let okAction = ActionSheetControllerAction(style: .Done, title: "OK", dismissesActionController: true ) { _ in
            AudioServicesPlaySystemSound(1103)
            let speechsynth = AVSpeechSynthesizer()
            let speechString = "Hey, You pressed OK, and dismissed the Action Sheet!"
            let speech = AVSpeechUtterance(string: speechString)
            speechsynth.speakUtterance(speech)
        }
        let cancelAction = ActionSheetControllerAction(style: .Cancel, title: "Cancel", dismissesActionController: true, handler: nil)
        let sheetController = ActionSheetController(style: style, title: "Hi there", message: "I have scores of grouped actions. Ok, well, not scores, but still…\n\nThe Alert Gun fires several alerts in rapid sucession. As you dismiss each alert, the next is shown.", cancelAction: cancelAction, okAction: okAction)
        
        let action1 = ActionSheetControllerAction(style: .Done, title: "Action 1", dismissesActionController: false) { controller in
            let action = AlertAction(title: "Hit me", style: .Default, enabled: true, isPreferredAction: true, handler: nil)
            let alertInfo = AlertInfo(title: "Success", message: "You picked action 1", actions: [action])
            QueuedAlertPresenter.sharedAlertPresenter.addAlert(alertInfo)
        }

        let action2 = ActionSheetControllerAction(style: .Additional, title: "Action 2", dismissesActionController: false) { controller in
            let action = AlertAction(title: "Hit me too", style: .Default, enabled: true, isPreferredAction: true, handler: nil)
            let alertInfo = AlertInfo(title: "Success", message: "You picked action 2", actions: [action])
            QueuedAlertPresenter.sharedAlertPresenter.addAlert(alertInfo)
        }

        let action3 = ActionSheetControllerAction(style: .Additional, title: "Action 3", dismissesActionController: false) { controller in
            let action = AlertAction(title: "Allright already!", style: .Default, enabled: true, isPreferredAction: true, handler: nil)
            let alertInfo = AlertInfo(title: "Success", message: "You picked action 3", actions: [action])
            QueuedAlertPresenter.sharedAlertPresenter.addAlert(alertInfo)
        }

        let groupedAction = GroupedActionSheetControllerAction(style: .Additional, actions: [action1, action2, action3])
        sheetController.addAction(groupedAction)

        let action4 = ActionSheetControllerAction(style: .Destructive, title: "Alert Gun", dismissesActionController: false) { controller in
            for i in 1...5 {
                let action = AlertAction(title: (i == 5) ? "Stop it!" : String(i), style: .Default, enabled: true, isPreferredAction: false, handler: nil)
                let alertInfo = AlertInfo(title: "Success", message: "You engaged the alert gun. This is alert number \(String(i)).", actions: [action])
                QueuedAlertPresenter.sharedAlertPresenter.addAlert(alertInfo)
            }
        }
        sheetController.addAction(action4)

        let label = UILabel(frame: CGRectZero)//CustomGrayView(frame: CGRectZero)
        sheetController.contentView = label
        sheetController.contentView?.heightAnchor.constraintEqualToConstant(80.0).active = true
        label.text = "I'm not a button. I'm the content view.."
        label.textAlignment = .Center
        label.adjustsFontSizeToFitWidth = true
        
        if style == .Dark {
            label.textColor = UIColor.lightTextColor()
        } else {
            label.textColor = UIColor.darkTextColor()
        }
        
        return sheetController
   
    }
    
    private func transparentBackgroundSheet() -> ActionSheetController {
        let pickerView = UIPickerView(frame: CGRectZero)
        pickerView.delegate = self.pickerViewDataSourceAndDelegate
        
        let okAction = ActionSheetControllerAction(style: .Done, image: UIImage(named: "shuffle"), dismissesActionController: true) { controller in
            var s = String()
            for comp in 0..<6 {
                let offset = (comp == 0) ? 97 - 32 : 97
                s.append(UnicodeScalar(offset + pickerView.selectedRowInComponent(comp)))
            }
            let action = AlertAction(title: "It's Poetry :-)", style: .Default, enabled: true, isPreferredAction: true, handler: nil)
            let alertInfo = AlertInfo(title: "Fantastic", message: "You wrote: \(s)", actions: [action])
            QueuedAlertPresenter.sharedAlertPresenter.addAlert(alertInfo)
        }
        
        let cancelAction = ActionSheetControllerAction(style: .Cancel, title: "Cancel", dismissesActionController: true, handler: nil)
        let sheetController = ActionSheetController(title: "Creator", message: "Form 6 letter words…", cancelAction: cancelAction, okAction: okAction)
        sheetController.disableBlurEffects = true
        
        sheetController.contentView = pickerView
        
        return sheetController
    }


    private func noBackgroundTapsSheet() -> ActionSheetController {
        let pickerView = UIDatePicker(frame: CGRectZero)
        
        let okAction = ActionSheetControllerAction(style: .Done, title: "OK", dismissesActionController: true) { controller in
            let date = pickerView.date
            let action = AlertAction(title: "Hurray!", style: .Default, enabled: true, isPreferredAction: true) {
                print("Dismissed!")
            }
            let alertInfo = AlertInfo(title: "Success", message: "You picked date: \(date.description)", actions: [action])
            QueuedAlertPresenter.sharedAlertPresenter.addAlert(alertInfo)
        }
        
        let cancelAction = ActionSheetControllerAction(style: .Cancel, title: "Cancel", dismissesActionController: true, handler: nil)
        let sheetController = ActionSheetController(title: "Date Picker", message: "Pick a date for your enjoyment…", cancelAction: cancelAction, okAction: okAction)
        sheetController.disableBackgroundTaps = true
        
        sheetController.contentView = pickerView
        
        return sheetController
    }

}



class CustomView: UIView {
    override func drawRect(rect: CGRect) {
        UIColor.yellowColor().colorWithAlphaComponent(0.8).setFill()
        UIRectFillUsingBlendMode(self.bounds, .Screen)
        
        UIColor.blueColor().setStroke()
        let path = UIBezierPath(ovalInRect: CGRectInset(self.bounds, 20.0, 30.0))
        path.stroke()
    }
}


class PickerDataSourceAndDelegate: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 6
    }
    
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 26
    }

    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return (component == 0) ? String(UnicodeScalar(97 - 32 + row)) : String(UnicodeScalar(97 + row))
    }
}