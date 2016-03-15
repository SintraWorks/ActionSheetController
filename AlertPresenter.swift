//
//  AlertPresenter.swift
//  RandomReminders
//
//  Created by Antonio Nunes on 29/02/16.
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
     Initializes an AlertAction instance with the passed in values. All parameteres have default values, so pass only those you need.
     - title: Optional title for the action. Defaults to an empty string.
     - style: Alert style (UIAlertActionStyle). Defaults to .Default
     - isPreferredAction: Whether the action is the preferred action of the alert. Defaults to false.
     - handler: Optional closure containing code to execute when the action is clicked.
     */
    public init(title: String = "", style: UIAlertActionStyle = .Default, enabled: Bool = true, isPreferredAction: Bool = false, handler: AlertActionHandler? = nil) {
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
    public init(title: String? = "", message: String? = "", style: UIAlertControllerStyle = .Alert, actions: [AlertAction]? = nil) {
        self.title = title
        self.message = message
        self.style = style
        self.actions = actions
    }
}


/**
 An AlertPresenter serializes the presentation of alerts. Use it when your code needs to present alerts in rapid succession, where the user won't be able to keep up with the alerts.
 
 Using AlertPresenter instead of UIAlertController directly, ensures your user gets to see all the alerts your code creates.
 
 To present an alert create an instance of AlertInfo then add it to the sharedAlertPresenter with addAlert(alertInfo).
 AlertInfo holds the information for an individual alert you want to present.
 */
public class AlertPresenter {
    public static let sharedAlertPresenter = AlertPresenter()
    
    var queuedAlerts = [AlertInfo]()
    var presentedAlert: AlertInfo?
    
    /**
     Adds an alert to the alert queue, and triggers presentation of the queued alerts.
     */
    public func addAlert(alertInfo: AlertInfo) {
        self.queuedAlerts.append(alertInfo)
        self.presentAlerts()
    }
    
    /**
     Presents queued alerts in succession.
     
     - Returns: true if an alert was presented, false if no alert was presented.
     */
    private func presentAlerts() -> Bool {
        if self.presentedAlert == nil {
            if let alertToPresent = self.queuedAlerts.first {
                self.presentedAlert = alertToPresent
                self.presentAlert(alertToPresent)
                return true
            }
        }
        return false
    }
    
    
    private func presentAlert(alertInfo :AlertInfo) {
        let alertController = UIAlertController(title: alertInfo.title, message:alertInfo.message, preferredStyle: alertInfo.style)
        
        if let actions = alertInfo.actions {
            for infoAction in actions {
                let alertAction = UIAlertAction(title: infoAction.title, style: infoAction.style) { action -> Void in
                    infoAction.handler?()
                    
                    self.presentedAlert = nil
                    self.queuedAlerts.removeFirst()
                    self.presentAlerts()
                }
                
                alertAction.enabled = infoAction.enabled
                alertController.addAction(alertAction)
                
                if infoAction.isPreferredAction {
                    alertController.preferredAction = alertAction
                }
            }
        }
        
        self.presentableViewController.presentViewControllerOnMainThread(alertController, animated: true, completion: nil)
    }
    
    // Ensure we present on a view controller that is not being dismissed, nor is presenting another view controller.
    private var presentableViewController: UIViewController {
        guard let rootViewController = UIApplication.sharedApplication().keyWindow?.rootViewController else { fatalError("There is no root view controller on the key window") }
        guard var presentedViewController = rootViewController.presentedViewController else {
            return rootViewController
        }

        while let candidate = presentedViewController.presentedViewController {
            presentedViewController = candidate
        }
        
        while presentedViewController.isBeingDismissed() {
            guard let ancestor = presentedViewController.presentingViewController else { fatalError("Exhausted view controller hierarchy, while looking for a controller that is not being dismissed") }
            presentedViewController = ancestor
        }

        return presentedViewController
    }
}
