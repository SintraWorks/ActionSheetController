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
class TableViewDelegate: NSObject, UITableViewDelegate {
    @IBOutlet var controller: UIViewController!
    
    var pickerViewDataSourceAndDelegate: UIPickerViewDelegate = PickerDataSourceAndDelegate()
    
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let rowIdentifier = self.rowIdentifierFromRowIndex((indexPath as NSIndexPath).row)
        
        var sheetController: ActionSheetController
        
        switch rowIdentifier {
        case .customView:
            sheetController = self.customSheet()
        case .datePickerView:
            sheetController = self.datePickerSheet()
        case .transparentBackground:
            sheetController = self.transparentBackgroundSheet()
        case .noBackgroundTaps:
            sheetController = self.noBackgroundTapsSheet()
        case .groupedActions:
            sheetController = self.groupedActionsSheet()
        case .viewController:
            sheetController = self.viewControllerSheet()
        }
        
        self.controller.present(sheetController, animated: true, completion: nil)
    }
}


extension TableViewDelegate {
    internal func rowIdentifierFromRowIndex(_ rowIndex: Int) -> RowIdentifier {
        guard let identifier = RowIdentifier(rawValue: rowIndex) else { fatalError("Invalid section") }
        return identifier
    }
}


extension TableViewDelegate {
    fileprivate func customSheet() -> ActionSheetController {
        let cancelAction = ActionSheetControllerAction(style: .cancel,
                                                       title: "Cancel",
                                                       dismissesActionController: true,
                                                       handler: nil)
        let sheetController = ActionSheetController(title: "Hi there",
                                                    message: "I'm a simple sheet boasting a custom view as my content view.",
                                                    cancelAction: cancelAction,
                                                    okAction: nil)

        let simpleView = CustomView(frame: CGRect.zero)
        simpleView.translatesAutoresizingMaskIntoConstraints = false
        simpleView.heightAnchor.constraint(equalToConstant: 100.0).isActive = true
        sheetController.contentView = simpleView
        
        return sheetController
    }


    fileprivate func datePickerSheet() -> ActionSheetController {
        let pickerView = UIDatePicker(frame: CGRect.zero)

        let okAction = ActionSheetControllerAction(style: .done,
                                                   title: "OK",
                                                   dismissesActionController: true) { controller in
            let date = pickerView.date
            let action = AlertAction(title: "Hurray!",
                                     style: .default,
                                     enabled: true,
                                     isPreferredAction: true) {
                print("Dismissed!")
            }
            let alertInfo = AlertInfo(title: "Success",
                                      message: "You picked date: \(date.description)",
                actions: [action])
            QueuedAlertPresenter.sharedAlertPresenter.addAlert(alertInfo)
        }
        
        let cancelAction = ActionSheetControllerAction(style: .cancel,
                                                       title: "Cancel",
                                                       dismissesActionController: true, handler: nil)
        let sheetController = ActionSheetController(title: "Date Picker",
                                                    message: "Pick a date for your enjoyment…",
                                                    cancelAction: cancelAction,
                                                    okAction: okAction)
        sheetController.blurEffectStyle = .systemUltraThinMaterial
        
        sheetController.contentView = pickerView
        
        return sheetController
    }
    
    
    fileprivate func groupedActionsSheet() -> ActionSheetController {
        let okAction = ActionSheetControllerAction(style: .done, title: "OK", dismissesActionController: true ) { _ in
            AudioServicesPlaySystemSound(1103)
            let speechsynth = AVSpeechSynthesizer()
            let speechString = "Hey, You pressed OK, and dismissed the Action Sheet!"
            let speech = AVSpeechUtterance(string: speechString)
            speechsynth.speak(speech)
        }
        let cancelAction = ActionSheetControllerAction(style: .cancel, title: "Cancel", dismissesActionController: true, handler: nil)
        let sheetController = ActionSheetController(title: "Hi there", message: "I have scores of grouped actions. Ok, well, not scores, but still…\n\nThe Alert Gun fires several alerts in rapid sucession. As you dismiss each alert, the next is shown.", cancelAction: cancelAction, okAction: okAction)
        
        let action1 = ActionSheetControllerAction(style: .done, title: "Action 1", dismissesActionController: false) { controller in
            let action = AlertAction(title: "Hit me", style: .default, enabled: true, isPreferredAction: true, handler: nil)
            let alertInfo = AlertInfo(title: "Success", message: "You picked action 1", actions: [action])
            QueuedAlertPresenter.sharedAlertPresenter.addAlert(alertInfo)
        }

        let action2 = ActionSheetControllerAction(style: .additional, title: "Action 2", dismissesActionController: false) { controller in
            let action = AlertAction(title: "Hit me too", style: .default, enabled: true, isPreferredAction: true, handler: nil)
            let alertInfo = AlertInfo(title: "Success", message: "You picked action 2", actions: [action])
            QueuedAlertPresenter.sharedAlertPresenter.addAlert(alertInfo)
        }
        
        let action3 = ActionSheetControllerAction(style: .additional, title: "Action 3", dismissesActionController: false) { controller in
            let action = AlertAction(title: "Allright already!", style: .default, enabled: true, isPreferredAction: true, handler: nil)
            let alertInfo = AlertInfo(title: "Success", message: "You picked action 3", actions: [action])
            QueuedAlertPresenter.sharedAlertPresenter.addAlert(alertInfo)
        }

        let groupedAction = GroupedActionSheetControllerAction(style: .additional, actions: [action1, action2, action3])
        sheetController.add(action: groupedAction)

        let action4 = ActionSheetControllerAction(style: .additional, title: "Alert Gun", image: UIImage(named: "globe_earth"), dismissesActionController: false) { controller in
            for i in 1...5 {
                let action = AlertAction(title: (i == 5) ? "Stop it!" : String(i), style: .default, enabled: true, isPreferredAction: false, handler: nil)
                let alertInfo = AlertInfo(title: "Success", message: "You engaged the alert gun. This is alert number \(String(i)).", actions: [action])
                QueuedAlertPresenter.sharedAlertPresenter.addAlert(alertInfo)
            }
        }
        sheetController.add(action: action4)
        
        if let action4Button = action4.view as? UIButton {
            action4Button.contentHorizontalAlignment = .left
            action4Button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 15)
            action4Button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        }

        let action5 = ActionSheetControllerAction(style: .destructive, title: "Delete something", dismissesActionController: false) { controller in
            let action = AlertAction(title: "OK", style: .default, enabled: true, isPreferredAction: true, handler: nil)
            let alertInfo = AlertInfo(title: "Not really…", message: "You tapped a fake delete action", actions: [action])
            QueuedAlertPresenter.sharedAlertPresenter.addAlert(alertInfo)
        }
        sheetController.add(action: action5)

        let label = UILabel(frame: CGRect.zero)//CustomGrayView(frame: CGRectZero)
        sheetController.contentView = label
        sheetController.contentView?.heightAnchor.constraint(equalToConstant: 80.0).isActive = true
        label.text = "I'm not a button. I'm the content view.."
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true

        label.textColor = .label

        return sheetController
    }
    
    fileprivate func transparentBackgroundSheet() -> ActionSheetController {
        let pickerView = UIPickerView(frame: CGRect.zero)
        pickerView.delegate = self.pickerViewDataSourceAndDelegate
        
        let okAction = ActionSheetControllerAction(style: .done, image: UIImage(named: "shuffle"), dismissesActionController: true) { controller in
            var s = String()
            for comp in 0..<6 {
                let offset = (comp == 0) ? 97 - 32 : 97
                s.append(String(describing: UnicodeScalar(UInt8(offset + pickerView.selectedRow(inComponent:comp)))))
            }
            let action = AlertAction(title: "It's Poetry :-)", style: .default, enabled: true, isPreferredAction: true, handler: nil)
            let alertInfo = AlertInfo(title: "Fantastic", message: "You wrote: \(s)", actions: [action])
            QueuedAlertPresenter.sharedAlertPresenter.addAlert(alertInfo)
        }
        
        let cancelAction = ActionSheetControllerAction(style: .cancel, title: "Cancel", dismissesActionController: true, handler: nil)
        let sheetController = ActionSheetController(title: "Creator", message: "Form 6 letter words…", cancelAction: cancelAction, okAction: okAction)
        sheetController.disableBlurEffects = true
        
        sheetController.contentView = pickerView
        
        return sheetController
    }

    fileprivate func noBackgroundTapsSheet() -> ActionSheetController {
        let pickerView = UIDatePicker(frame: CGRect.zero)
        
        let okAction = ActionSheetControllerAction(style: .done, title: "OK", dismissesActionController: true) { controller in
            let date = pickerView.date
            let action = AlertAction(title: "Hurray!", style: .default, enabled: true, isPreferredAction: true) {
                print("Dismissed!")
            }
            let alertInfo = AlertInfo(title: "Success", message: "You picked date: \(date.description)", actions: [action])
            QueuedAlertPresenter.sharedAlertPresenter.addAlert(alertInfo)
        }
        
        let cancelAction = ActionSheetControllerAction(style: .cancel, title: "Cancel", dismissesActionController: true, handler: nil)
        let sheetController = ActionSheetController(title: "Date Picker", message: "Pick a date for your enjoyment…", cancelAction: cancelAction, okAction: okAction)
        sheetController.disableBackgroundTaps = true
        
        sheetController.contentView = pickerView
        
        return sheetController
    }

    fileprivate func viewControllerSheet() -> ActionSheetController {
        let viewController = CustomViewController()
        
        let okAction = ActionSheetControllerAction(style: .done, title: "OK", dismissesActionController: true) { controller in
            let date = viewController.pickerView.date
            let action = AlertAction(title: "Hurray!", style: .default, enabled: true, isPreferredAction: true) {
                print("Dismissed!")
            }
            let alertInfo = AlertInfo(title: "Success", message: "You picked date: \(date.description)", actions: [action])
            QueuedAlertPresenter.sharedAlertPresenter.addAlert(alertInfo)
        }
        
        let cancelAction = ActionSheetControllerAction(style: .cancel, title: "Cancel", dismissesActionController: true) { controller in
            print("Canceled!")
        }
        let sheetController = ActionSheetController(title: "Date Picker in Custom View Controller", message: "Pick a date for no particular reason…", cancelAction: cancelAction, okAction: okAction)
        
        sheetController.contentViewController = viewController
        
        return sheetController
    }
}

class CustomView: UIView {
    override func draw(_ rect: CGRect) {
        UIColor.yellow.withAlphaComponent(0.8).setFill()
        UIRectFillUsingBlendMode(self.bounds, .screen)
        
        UIColor.blue.setStroke()
        let path = UIBezierPath(ovalIn: self.bounds.insetBy(dx: 20.0, dy: 30.0))
        path.stroke()
    }
}

class PickerDataSourceAndDelegate: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        6
    }
    
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        26
    }

    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let baseChar: Character = (component == 0) ? "A" : "a"
        guard
            let baseAscii = baseChar.asciiValue,
            let scalar = UnicodeScalar(Int(baseAscii) + row)
            else { return nil }

        return String(scalar)
    }
}

// MARK: - Custom View Controller
class CustomViewController: UIViewController {
    let pickerView = UIDatePicker(frame: CGRect(x: 0.0, y: 0.0, width: 100.0, height: 200.0))

    override func viewDidLoad() {
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pickerView)
		NSLayoutConstraint.activate([
            pickerView.topAnchor.constraint(equalTo: view.topAnchor),
            pickerView.leftAnchor.constraint(equalTo: view.leftAnchor),
            pickerView.rightAnchor.constraint(equalTo: view.rightAnchor),
            pickerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
