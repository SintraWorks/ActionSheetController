//
//  ActionSheetControllerAction.swift
//  RandomReminders
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

// MARK: Action Style: ActionSheetControllerActionStyle

/// The action style determines the display properties and placement of the action button.

public enum ActionSheetControllerActionStyle: Int {
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

/// A block of code to be executed when the action is activated.
public typealias ActionSheetControllerActionHandler = (ActionSheetController) -> ()

/// An ActionSheetControllerAction instance represents an action on the ActionSheetController that can be tapped by the user.
/// It has a title or image for identifying the action and a handler which is called when the action has been tapped by the user.

public class ActionSheetControllerAction {
    /// The action's title
    var title: String?
    /// The action's image. It will not be shown if the action also has a title.
    public var image: UIImage?
    /// The action's style
    var style: ActionSheetControllerActionStyle = .Done
    /// Controls whether the action dismisses the controller when selected.
    var dismissesActionController: Bool = false
    /// An optional closure containing the code to perform when the action is selected
    var handler: ActionSheetControllerActionHandler?
    
    var controller: ActionSheetController?
    
    /// Provide at least a title or an image. (But not both. The title overrides the image.)
    /// If you want the action to dismiss the controller when clicked set dismissesActionController to true.
    ///
    public init(style: ActionSheetControllerActionStyle = .Done, title: String? = nil, image: UIImage? = nil, dismissesActionController: Bool = false, handler:ActionSheetControllerActionHandler? = nil) {
        self.style = style
        self.title = title
        self.image = image
        self.dismissesActionController = dismissesActionController
        if self.dismissesActionController {
            // Important to call the handler *after* dismissing the view controller, since we need to be able to detect whether the current controller is being dismissed, to decide how to present the next view controller.
            self.handler = { controller in
                if controller.modalPresentationStyle == .popover || controller.animationConstraint != nil {
                    controller.dismiss(animated: true, completion:nil)
                } else {
                    controller.dismiss(animated: false, completion:nil)
                }
                
                if let handler = handler {
                    handler(controller)
                }
            }
        } else if let handler = handler {
            self.handler = handler
        }
    }
    
    
    public lazy var view: UIView = {
        return self.loadView()
    }()
    
    
    fileprivate func loadView() -> UIView {
        guard let controller = self.controller else { fatalError("Controller not set when loading view on an ActionSheetControllerAction") }
        
        let actionButton = button(for: controller)
        
        if let title = self.title {
            actionButton.setTitle(title, for: .normal)
        }
        
        if let image = self.image {
            actionButton.setImage(image, for: .normal)
        }
        
        if self.style == .Destructive {
            actionButton.setTitleColor(UIColor.red, for: .normal)
        } else {
            let defaultSystemColor = UIButton(type: .system).titleLabel?.textColor
            if let controller = self.controller, controller.blurEffectsDisabled == false {
                actionButton.setTitleColor(defaultSystemColor, for: .normal)
            }
        }
        
        return actionButton;
    }
    
    private func button(for controller: ActionSheetController) -> UIButton {
        func contextAwareBackgroundColor() -> UIColor {
            switch controller.style {
            case .Light:
                return controller.blurEffectsDisabled ? LightColor : TransparentLightColor
            case .Dark:
                return controller.blurEffectsDisabled ? DarkColor : TransparentDarkColor
            }
        }

        let actionButton = UIButton(type: controller.blurEffectsDisabled ? .system : .custom)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.backgroundColor = contextAwareBackgroundColor()

        actionButton.addTarget(self, action: #selector(ActionSheetControllerAction.viewTapped), for: .touchUpInside)
        
        if self.style == .Cancel {
            actionButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: UIFont.buttonFontSize)
        } else {
            actionButton.titleLabel?.font = UIFont.systemFont(ofSize: UIFont.buttonFontSize)
        }
        
        if let controller = self.controller {
            if !controller.blurEffectsDisabled {
                actionButton.setBackgroundImage(self.imageWithColor(color: UIColor(white: 1.0, alpha: 0.3)), for: .highlighted)
            } else {
                switch controller.style {
                case .Light:
                    actionButton.setBackgroundImage(self.imageWithColor(color: UIColor(white: 0.9, alpha: 1.0)), for: .highlighted)
                    break;
                case .Dark:
                    actionButton.setBackgroundImage(self.imageWithColor(color: UIColor(white: 0.2, alpha: 1.0)), for: .highlighted)
                    break;
                }
            }
        }

        actionButton.heightAnchor.constraint(equalToConstant: StackViewRowHeightAnchorConstraint).isActive = true
        
        return actionButton
    }
    
    
    @objc private func viewTapped() {
        if let handler = self.handler,
            let controller = self.controller {
            handler(controller)
        }
    }
    
    private func imageWithColor(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
}

// MARK: - Grouped Actions

/// A GroupedActionSheetControllerAction represents a grouping of ActionControllerActions.
///
/// An ActionSheetController uses one row for every action that has been added. GroupedActionSheetControllerAction enables showing multiple ActionControllerActions in one row.

public class GroupedActionSheetControllerAction: ActionSheetControllerAction {
    /// The grouped actions of the ActionControllerGroupedAction.
    var actions: [ActionSheetControllerAction] = []
    
    /// Pass in the action style, and an array of actions to be shown on a single row.
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
    
    override fileprivate func loadView() -> UIView {
        guard let controller = self.controller else { fatalError("Controller not set when loading view on an GroupedActionSheetControllerAction") }
        
        let stackView = UIStackView(frame: CGRect.zero)
        stackView.axis = .horizontal
        
        let separatorViewWidth: CGFloat = 1.0 / UIScreen.main.scale
        func separatorView() -> UIView {
            let separatorView = UIView(frame: CGRect.zero)
            separatorView.backgroundColor = UIColor.darkGray
            separatorView.widthAnchor.constraint(equalToConstant: separatorViewWidth).isActive = true
            separatorView.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)
            return separatorView
        }
        
        var precedingActionView: UIView? = nil
        for action in self.actions {
            action.view.setContentHuggingPriority(UILayoutPriority.defaultLow, for:.horizontal)
            stackView.addArrangedSubview(action.view)
            if action !== self.actions.last {
                stackView.addArrangedSubview(separatorView())
            }
            
            if let precedingView = precedingActionView {
                action.view.widthAnchor.constraint(equalTo: precedingView.widthAnchor).isActive = true
            }
            
            precedingActionView = action.view
        }
        
        return stackView
    }
}
