//
//  QueuedAlertPresenter.swift
//  RandomReminders
//
//  Created by Antonio Nunes on 29/02/16.
//  Copyright © 2016 SintraWorks. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is furnished
//  to do so, subject to the following conditions:
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


public typealias AlertActionHandler = () -> ()

/**
 An AlertAction instance encapsulates all the required information to create an alert action.
 */
public struct AlertAction {
    var title: String
    var style: UIAlertActionStyle
    var handler: AlertActionHandler?
    var enabled: Bool
    var isPreferredAction: Bool
    
    /**
     Initializes an AlertAction instance with the passed in values. All parameters have default values, so pass only those you need.
     - title: Optional title for the action. Defaults to an empty string.
     - style: Alert style (UIAlertActionStyle). Defaults to .Default
     - isPreferredAction: Whether the action is the preferred action of the alert. Defaults to false.
     - handler: Optional closure containing code to execute when the action is clicked.
     */
    public init(title: String = "", style: UIAlertActionStyle = .default, enabled: Bool = true, isPreferredAction: Bool = false, handler: AlertActionHandler? = nil) {
        self.title = title
        self.style = style
        self.enabled = enabled
        self.isPreferredAction = isPreferredAction
        self.handler = handler
    }
}


/**
 An AlertInfo instance encapsulates all the required information to create an Alert, including its actions.
 */
public struct AlertInfo {
    var title: String?
    var message: String?
    var style: UIAlertControllerStyle
    var actions: [AlertAction]?
    
    /**
     Initializes an AlertInfo instance with the passed in values. All parameteres have default values, so pass only those you need.
     - title: Optional title for the alert. Defaults to an empty string.
     - message: Optional message body for the alert. Defaults to an empty string
     - style: Alert style (UIAlertControllerStyle). Defaults to .Alert
     - actions: Optional array of AlertActions. Defaults to nil.
     */
    public init(title: String? = "", message: String? = "", style: UIAlertControllerStyle = .alert, actions: [AlertAction]? = nil) {
        self.title = title
        self.message = message
        self.style = style
        self.actions = actions
    }
}


/**
 A QueuedAlertPresenter serializes the presentation of alerts. Use it when your code needs to present alerts in rapid succession, where the user may not be able to keep up with the alerts.
 
 Using QueuedAlertPresenter instead of UIAlertController directly, ensures your user gets to see all the alerts your code creates.
 
 To present an alert create an instance of AlertInfo then add it to the sharedAlertPresenter with addAlert(alertInfo).
 AlertInfo holds the information for an individual alert you want to present.
 */
open class QueuedAlertPresenter {
    open static let sharedAlertPresenter = QueuedAlertPresenter()
    
    fileprivate var queuedAlerts = [AlertInfo]()
    fileprivate var presentedAlert: AlertInfo?
    
    /**
     Adds an alert to the alert queue, and triggers presentation of the queued alerts.
     */
    open func addAlert(_ alertInfo: AlertInfo) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        self.queuedAlerts.append(alertInfo)
        self.presentAlerts()
    }
    
    /**
     Presents queued alerts in succession.
     
     - Returns: true if an alert was presented, false if no alert was presented.
     */
    @discardableResult fileprivate func presentAlerts() -> Bool {
        if self.presentedAlert == nil,
            let alertToPresent = self.queuedAlerts.first {
            self.presentedAlert = alertToPresent
            self.presentAlert(alertToPresent)
            return true
        }
        return false
    }
    
    
    fileprivate func presentAlert(_ alertInfo :AlertInfo) {
        let alertController = UIAlertController(title: alertInfo.title, message:alertInfo.message, preferredStyle: alertInfo.style)
        
        if let actions = alertInfo.actions {
            for infoAction in actions {
                let alertAction = UIAlertAction(title: infoAction.title, style: infoAction.style) { action -> Void in
                    infoAction.handler?()
                    
                    self.presentedAlert = nil
                    self.queuedAlerts.removeFirst()
                    self.presentAlerts()
                }
                
                alertAction.isEnabled = infoAction.enabled
                alertController.addAction(alertAction)
                
                if #available(iOS 9.0, *) {
                    if infoAction.isPreferredAction {
                        alertController.preferredAction = alertAction
                    }
                }
            }
        }
        
        self.validViewControllerForPresentation.presentViewControllerOnMainThread(alertController, animated: true, completion: nil)
    }
    
    
    // Ensure we present on a view controller that is neither being dismissed, nor presenting another view controller.
    fileprivate var validViewControllerForPresentation: UIViewController {
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else { fatalError("There is no root view controller on the key window") }
        var validController = UIViewController.topViewControllerForViewController(rootViewController)
        
        while validController.isBeingDismissed {
            guard let ancestor = validController.presentingViewController else { fatalError("Exhausted view controller hierarchy, while looking for a controller that is not being dismissed") }
            validController = ancestor
        }
        
        return validController
    }
}
