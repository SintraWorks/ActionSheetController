//
//  ActionSheetControllerAction.swift
//  RandomReminders
//
//  Created by Antonio Nunes on 14/03/16.
//  Copyright © 2016 SintraWorks. All rights reserved.
//

import UIKit

// MARK: Action Style: ActionSheetControllerActionStyle

/// The action style determines the display properties and placement of the action button.

public enum ActionSheetControllerActionStyle {
    /// The button is displayed with a regular font and positioned right below the content view.
    case Done
    /// The button is displayed with a bold font and positioned below all done buttons (or the content view if there are no done buttons).
    case Cancel
    /// The button is displayed with a standard font and positioned right below the content view. Currently only supported when blur effects are disabled.
    case Destructive
    /// The button is displayed with a regular font and positioned above the content view.
    case Additional
}

// MARK: - Individual Actions

public typealias ActionSheetControllerActionHandler = (ActionSheetController) -> ()

/// An ActionSheetControllerAction instance represents an action on the ActionSheetController that can be tapped by the user.
/// It has a title or image for identifying the action and a handler which is called when the action has been tapped by the user.

public class ActionSheetControllerAction {
    /// The action's title
    var title: String?
    /// The action's image
    public var image: UIImage?
    /// The action's style
    var style: ActionSheetControllerActionStyle = .Done
     /// Controls whether the action dismisses the controller when selected.
    var dismissesActionController: Bool = false
    /// An optional closure containing the code to perform when the action is selected
    var handler: ActionSheetControllerActionHandler?
    
    var controller: ActionSheetController?
    
    
    public init(style: ActionSheetControllerActionStyle = .Done, title: String? = nil, image: UIImage? = nil, dismissesActionController: Bool = false, handler:ActionSheetControllerActionHandler? = nil) {
        self.style = style
        self.title = title
        self.image = image
        self.dismissesActionController = dismissesActionController
        if self.dismissesActionController {
            // Important to call the handler *after* dismissing the view controller, since we need to be able to detect whether the current controller is being dismissed, to decide how to present the next view controller.
            self.handler = { controller in
                if controller.modalPresentationStyle == .Popover || controller.yConstraint != nil {
                    controller.dismissViewControllerAnimated(true, completion:nil)
                } else {
                    controller.dismissViewControllerAnimated(false, completion:nil)
                }
                
                if let handler = handler {
                    handler(controller)
                }
            }
        } else if let handler = handler {
            self.handler = handler
        }
    }
    
    
    lazy var view: UIView = {
        return self.loadView()
    }()
    
    
    private func loadView() -> UIView {
        guard let controller = self.controller else { fatalError("Controller not set when loading view on an ActionSheetControllerAction") }
        func contextAwareBackgroundColor() -> UIColor {
            switch controller.style {
            case .White:
                return controller.blurEffectsDisabled ? whiteColor : transparentWhiteColor
            case .Black:
                return controller.blurEffectsDisabled ? blackColor : transparentBlackColor
            }
        }
        
        let systemButton = UIButton(type: .System)
        let defaultSystemColor = systemButton.titleLabel?.textColor
        
        let buttonType: UIButtonType = controller.blurEffectsDisabled ? .System : .Custom;
        let actionButton = UIButton(type: buttonType)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.backgroundColor = contextAwareBackgroundColor()
        actionButton.addTarget(self, action: Selector("viewTapped"), forControlEvents: .TouchUpInside)
        
        if self.style == .Cancel {
            actionButton.titleLabel?.font = UIFont.boldSystemFontOfSize(UIFont.buttonFontSize())
        } else {
            actionButton.titleLabel?.font = UIFont.systemFontOfSize(UIFont.buttonFontSize())
        }
        
        if let controller = self.controller {
            if !controller.blurEffectsDisabled {
                actionButton.setBackgroundImage(self.imageWithColor(UIColor(white: 1.0, alpha: 0.3)), forState: .Highlighted)
            } else {
                switch controller.style {
                case .White:
                    actionButton.setBackgroundImage(self.imageWithColor(UIColor(white: 0.9, alpha: 1.0)), forState: .Highlighted)
                    break;
                case .Black:
                    actionButton.setBackgroundImage(self.imageWithColor(UIColor(white: 0.2, alpha: 1.0)), forState: .Highlighted)
                    break;
                }
            }
        }
        
        if let title = self.title {
            actionButton.setTitle(title, forState: .Normal)
        } else if let image = self.image {
            actionButton.setImage(image, forState: .Normal)
        } else {
            actionButton.setTitle("Untitled", forState: .Normal)
        }
        
        actionButton.heightAnchor.constraintEqualToConstant(stackViewRowHeightAnchorConstraint).active = true
        
        if self.style == .Destructive {
            actionButton.setTitleColor(UIColor.redColor(), forState: .Normal)
        } else {
            if let controller = self.controller where controller.blurEffectsDisabled == false {
                actionButton.setTitleColor(defaultSystemColor, forState: .Normal)
            }
        }
        
        return actionButton;
    }
    
    
    @objc private func viewTapped() {
        if let handler = self.handler,
            let controller = self.controller {
                handler(controller)
        }
    }
    
    private func imageWithColor(color: UIColor) -> UIImage {
        let rect = CGRectMake(0, 0, 1, 1)
        
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
}

// MARK: - Grouped Actions

/// A GroupedActionSheetControllerAction represents a grouping of ActionControllerActions.
///
/// An ActionSheetController uses one row for every action that has been added. GroupedActionSheetControllerAction enables showing multiple ActionControllerActions in one row.

public class GroupedActionSheetControllerAction: ActionSheetControllerAction {
    /// The grouped actions of the ActionControllerGroupedAction.
    var actions: [ActionSheetControllerAction] = []
    
    
    public init(style: ActionSheetControllerActionStyle, actions: [ActionSheetControllerAction]) {
        super.init(style: style, title: nil, dismissesActionController: false, handler: nil)
        self.style = style
        self.actions = actions
    }
    
    override var controller: ActionSheetController? {
        get {
            return self.actions.first?.controller
        }
        set {
            for action in self.actions {
                action.controller = newValue
            }
        }
    }
    
    private override func loadView() -> UIView {
        guard let controller = self.controller else { fatalError("Controller not set when loading view on an GroupedActionSheetControllerAction") }
        func contextAwareBackgroundColor() -> UIColor {
            switch controller.style {
            case .White:
                return controller.blurEffectsDisabled ? whiteColor : transparentWhiteColor
            case .Black:
                return controller.blurEffectsDisabled ? blackColor : transparentBlackColor
            }
        }
        
        let stackView = UIStackView(frame: CGRectZero)
        stackView.axis = .Horizontal
        stackView.distribution = .Fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        if let controller = self.controller {
            stackView.backgroundColor = contextAwareBackgroundColor()
        }
        stackView.heightAnchor.constraintEqualToConstant(stackViewRowHeightAnchorConstraint).active = true
        
        let separatorViewWidth: CGFloat = 1.0 / UIScreen.mainScreen().scale
        func separatorView() -> UIView {
            let separatorView = UIView(frame: CGRectZero)
            separatorView.backgroundColor = UIColor.darkGrayColor()
            separatorView.widthAnchor.constraintEqualToConstant(separatorViewWidth).active = true
            separatorView.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)
            return separatorView
        }
        
        var precedingActionView: UIView? = nil
        for action in self.actions {
            action.view.setContentHuggingPriority(UILayoutPriorityDefaultLow, forAxis:.Horizontal)
            action.view.backgroundColor = contextAwareBackgroundColor()
            stackView.addArrangedSubview(action.view)
            if action !== self.actions.last {
                stackView.addArrangedSubview(separatorView())
            }
            
            if let precedingView = precedingActionView {
                stackView.addConstraint(NSLayoutConstraint(item: action.view, attribute: .Width, relatedBy: .Equal, toItem: precedingView, attribute: .Width, multiplier: 1.0, constant: 0.0))
            }
            
            precedingActionView = action.view
        }
        
        return stackView
    }
}
