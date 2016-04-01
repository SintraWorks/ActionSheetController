//
//  ActionSheetController.swift
//  RandomReminders
//
//  Created by Antonio Nunes on 21/02/16.
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

internal let LightColor = UIColor.whiteColor()
internal let TransparentLightColor = UIColor.whiteColor().colorWithAlphaComponent(0.75)
internal let DarkColor = UIColor.blackColor()
internal let TransparentDarkColor = UIColor.blackColor().colorWithAlphaComponent(0.75)
internal let UnblurredBackgroundColorForLightStyle = DarkColor.colorWithAlphaComponent(0.2)
internal let UnblurredBackgroundColorForDarkStyle = LightColor.colorWithAlphaComponent(0.2)
internal let ClearColor = UIColor.clearColor()
internal let StackViewRowHeightAnchorConstraint: CGFloat = 44.0


// MARK: - Controller

/// The controller style determines the overall theme of the controller. Either White or Black.

public enum ActionSheetControllerStyle: Int {
    /// The light theme, with a light background.
    case Light
    /// The dark theme, with a dark background.
    case Dark
}


/// iOS control for presenting a view in a style reminiscent of an action sheet/alert.
/// You can add a custom view, and any number of buttons to represent and handle actions.
public class ActionSheetController: UIViewController, UIViewControllerTransitioningDelegate {
    private let interStackViewheightAnchorConstraint: CGFloat = 16.0
    private var cornerRadius: CGFloat {
        get {
            return (UIDevice.currentDevice().userInterfaceIdiom == .Pad) ? 8.0 : 4.0
        }
    }
    
    private(set) var style: ActionSheetControllerStyle = .Light
    
    /// The message shown in the header of the controller.
    public var message: String?
    
    /// Whether to disable background taps. When true, tapping outside the controller has no effect.
    /// When false, tapping outside the controller dismisses the controller without triggering any actions.
    public var disableBackgroundTaps: Bool = false
    
    var additionalActions: [ActionSheetControllerAction] = []
    var doneActions: [ActionSheetControllerAction] = []
    var cancelActions: [ActionSheetControllerAction] = []
    
    var animationConstraint: NSLayoutConstraint?
    
    lazy private var backgroundView: UIView = {
        var backgroundView: UIView? = nil
        if self.blurEffectsDisabled {
            backgroundView = UIView(frame: CGRectZero)
            backgroundView?.backgroundColor = self.style == .Light ?  UnblurredBackgroundColorForLightStyle : UnblurredBackgroundColorForDarkStyle
        } else {
            // Note that on older hardware the blur effect may not render correctly (although still acceptably).
            let effect = UIBlurEffect(style: self.backgroundBlurEffectStyleForCurrentStyle)
            backgroundView = UIVisualEffectView(effect: effect)
        }
        
        guard let resultView = backgroundView else { fatalError("Could not create backgroundView") }
        resultView.translatesAutoresizingMaskIntoConstraints = false
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ActionSheetController.backgroundViewTapped))
        resultView.addGestureRecognizer(tapRecognizer)
        
        return resultView
    }()
    
    /// Returns the outer stack view that will hold the inner stackviews adn separator view as appropriate.
    lazy private var outerStackView: UIStackView = {
        return self.stackView()
    }()
    
    /// The stack view to be used as the top stack view. This stack view holds all actions except the cancel actions, and it holds the controller's content view.
    lazy private var topStackView: UIStackView = {
        return self.stackView()
    }()
    
    /// The stack view to be used as the bottom stack view. This stack view holds only the cancel actions, if any.
    lazy private var bottomStackView: UIStackView = {
        return self.stackView()
    }()
    
    /// Set the contentView to hold the view you want to display. If you need only buttons, do not set the content view.
    public var contentView: UIView?
    
    /// Returns a UIView to be used as a separator row between the top and bottom stack views.
    private func interStackViewSeparatorView() -> UIView {
        let emptyView = UIView(frame: CGRectZero)
        emptyView.backgroundColor = ClearColor
        emptyView.heightAnchor.constraintEqualToConstant(self.interStackViewheightAnchorConstraint).active = true
        return emptyView
    }
    
    /// Returns a UILabel with the majority of settings preapared for use in this controller. Only the font needs setting by the caller.
    private func label(text: String) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.textAlignment = .Center
        label.textColor = self.style == .Light ? UIColor.darkGrayColor() : UIColor.lightGrayColor()
        label.backgroundColor = UIColor.clearColor()
        label.numberOfLines = 0
        return label
    }
    
    /// Returns a UIStackView prepared for use in this controller.
    private func stackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .Vertical
        stackView.distribution = .Fill
        stackView.alignment = .Fill
        return stackView
    }
    
    /// Returns a view to enclose a stack view (top ro bottom), prepared such that the stack view will display rounded corners.
    private func roundedCornerContainerForView(view: UIView) -> UIView {
        let roundedCornerContainerView = UIView(frame: CGRectZero)
        roundedCornerContainerView.layer.cornerRadius = 4
        roundedCornerContainerView.layer.masksToBounds = true
        roundedCornerContainerView.backgroundColor = self.contextAwareBackgroundColor
        
        roundedCornerContainerView.addSubview(view)
        view.leftAnchor.constraintEqualToAnchor(roundedCornerContainerView.leftAnchor).active = true
        view.topAnchor.constraintEqualToAnchor(roundedCornerContainerView.topAnchor).active = true
        view.rightAnchor.constraintEqualToAnchor(roundedCornerContainerView.rightAnchor).active = true
        view.bottomAnchor.constraintEqualToAnchor(roundedCornerContainerView.bottomAnchor).active = true
        
        return roundedCornerContainerView
    }
    
    
    private var contextAwareLightColor: UIColor {
        return self.blurEffectsDisabled ? LightColor : TransparentLightColor
    }
    
    private var contextAwareDarkColor: UIColor {
        return self.blurEffectsDisabled ? DarkColor : TransparentDarkColor
        
    }
    
    private var contextAwareBackgroundColor: UIColor {
        switch self.style {
        case .Light:
            return self.contextAwareLightColor
        case .Dark:
            return self.contextAwareDarkColor
        }
    }
    
    /// Whether blur effects are disabled or not.
    public var disableBlurEffects: Bool = false
    public var blurEffectsDisabled: Bool {
        get {
            if UIAccessibilityIsReduceTransparencyEnabled() {
                return true
            }
            return disableBlurEffects
        }
    }
    
    private var backgroundBlurEffectStyleForCurrentStyle: UIBlurEffectStyle {
        switch (self.style) {
        case .Light:
            return .Dark
        case .Dark:
            return .Light;
        }
    }
    
    public var disableBouncingEffects: Bool = false
    /// Set to true to disable bouncing when showing the controller.
    public var bouncingEffectsDisabled: Bool {
        get {
            if UIAccessibilityIsReduceMotionEnabled() {
                return true
            }
            
            return disableBouncingEffects
        }
    }
    
    /// Returns a view that separates the successive rows within the top ro bottom stack view.
    private func separatorView() -> UIView {
        let separatorViewHeight: CGFloat = 1.0 / UIScreen.mainScreen().scale
        let separatorView = UIView(frame: CGRectZero)
        separatorView.backgroundColor = UIColor.darkGrayColor()
        separatorView.heightAnchor.constraintEqualToConstant(separatorViewHeight).active = true
        return separatorView
    }
    
    
    /// Initializer. Style defaults to White. Generally you will want to pass in at least a title and/or a message.
    /// Pass in any of the other arguments as needed. If you want to add more actions than the Cancel and/or OK actions, you can do so after instantiation.
    /// - Parameter style: The controller's style. Either White or Black.
    /// - Parameter title: The title shown in the controller's header.
    /// - Parameter message: The message shown in the controller's header.
    /// - Parameter cancelAction: A action appropriately configured for cancelling abd dismissing the controller.
    /// - Parameter okAction: A action appropriately configured for actioning on and dismissing the controller.
    public init(style: ActionSheetControllerStyle = .Light, title: String?, message: String?, cancelAction: ActionSheetControllerAction? = nil, okAction: ActionSheetControllerAction? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.style = style
        self.title = title
        self.message = message
        if let cancelAction = cancelAction {
            self.addAction(cancelAction)
        }
        if let okAction = okAction {
            self.addAction(okAction)
        }
        self.setup()
    }
    
    
    /// Initializer when loaded from nib.
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.setup()
    }
    
    /// Initializer when loaded from a decoder.
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupViewHierarchy()
    }
    
    
    public func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animationController = ActionControllerAnimationController()
        animationController.animationStyle = .Presenting
        return animationController
    }
    
    
    public func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animationController = ActionControllerAnimationController()
        animationController.animationStyle = .Dismissing
        return animationController
    }
    
    private func setup() {
        self.modalPresentationStyle = .OverCurrentContext
        self.transitioningDelegate = self // transitioningDelegate is a weak property, so no retain cycle created here.
    }
    
    
    private func setupViewHierarchy() {
        self.view.backgroundColor = UIColor.clearColor()
        self.view.translatesAutoresizingMaskIntoConstraints = false
        
        let outerStackView = self.outerStackView
        
        self.setupTopStackView()
        let topContainer = self.roundedCornerContainerForView(self.topStackView)
        outerStackView.addArrangedSubview(topContainer)
        
        if self.cancelActions.count > 0 {
            outerStackView.addArrangedSubview(self.interStackViewSeparatorView())
            self.setupBottomStackView()
            let bottomContainer = self.roundedCornerContainerForView(bottomStackView)
            outerStackView.addArrangedSubview(bottomContainer)
        }
        
        self.view.addSubview(outerStackView)
        outerStackView.centerXAnchor.constraintEqualToAnchor(self.view.centerXAnchor).active = true
        outerStackView.widthAnchor.constraintEqualToAnchor(self.view.widthAnchor, constant: -20.0).active = true
        outerStackView.bottomAnchor.constraintEqualToAnchor(self.view.bottomAnchor, constant: -8.0).active = true
    }
    
    
    private func setupTopStackView() {
        if self.title != nil || self.message != nil {
            let headerView = UIView()
            var titleLabel: UILabel? = nil
            
            if let title = self.title {
                let label = self.label(title)
                label.font = UIFont.boldSystemFontOfSize(UIFont.systemFontSize())
                
                headerView.addSubview(label)
                label.centerXAnchor.constraintEqualToAnchor(headerView.centerXAnchor).active = true
                label.widthAnchor.constraintEqualToAnchor(headerView.widthAnchor, constant: -20.0).active = true
                label.topAnchor.constraintEqualToAnchor(headerView.topAnchor, constant: 10.0).active = true
                
                if self.message == nil {
                    label.bottomAnchor.constraintEqualToAnchor(headerView.bottomAnchor, constant: -10.0).active = true
                }
                
                titleLabel = label
            }
            
            if let message = self.message {
                let label = self.label(message)
                label.font = UIFont.systemFontOfSize(UIFont.systemFontSize())
                
                headerView.addSubview(label)
                label.centerXAnchor.constraintEqualToAnchor(headerView.centerXAnchor).active = true
                label.widthAnchor.constraintEqualToAnchor(headerView.widthAnchor, constant: -20.0).active = true
                label.bottomAnchor.constraintEqualToAnchor(headerView.bottomAnchor, constant: -10.0).active = true
                
                let relatedAnchor = (titleLabel != nil) ? titleLabel!.bottomAnchor : headerView.topAnchor
                label.topAnchor.constraintEqualToAnchor(relatedAnchor, constant: 10.0).active = true
            }
            
            self.topStackView.addArrangedSubview(headerView)
            self.topStackView.addArrangedSubview(self.separatorView())
        }
        
        for action in self.additionalActions {
            self.topStackView.addArrangedSubview(action.view)
            self.topStackView.addArrangedSubview(separatorView())
        }
        
        
        if let middleView = self.contentView {
            self.topStackView.addArrangedSubview(middleView)
            self.topStackView.addArrangedSubview(separatorView())
        }
        
        for action in self.doneActions {
            self.topStackView.addArrangedSubview(action.view)
            if action !== self.doneActions.last! {
                self.topStackView.addArrangedSubview(separatorView())
            }
        }
    }
    
    
    private func setupBottomStackView() {
        for action in self.cancelActions {
            self.bottomStackView.addArrangedSubview(action.view)
            if action !== self.cancelActions.last! {
                self.bottomStackView.addArrangedSubview(separatorView())
            }
        }
    }
    
    /// Used to add actions, beyond the Cancel and OK actions that can be added in the initializer.
    public func addAction(action: ActionSheetControllerAction) {
        switch action.style {
        case .Additional:
            self.additionalActions.append(action)
        case .Done:
            self.doneActions.append(action)
        case .Cancel:
            self.cancelActions.append(action)
        case .Destructive:
            self.doneActions.append(action)
        }
        
        action.controller = self
    }
    
    
    @objc private func backgroundViewTapped() {
        if !self.disableBackgroundTaps {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
}


private enum ActionControllerAnimationStyle {
    case Presenting
    case Dismissing
}

// MARK: - Animation (only on .Phone idiom devices)
class ActionControllerAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    private var animationStyle: ActionControllerAnimationStyle = .Presenting
    
    private let longTransitionDuration: NSTimeInterval = 1.5
    private let shortTransitionDuration: NSTimeInterval = 0.3
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        guard let containerView = transitionContext.containerView() else { return }
        
        if self.animationStyle == .Presenting {
            guard let actionController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as? ActionSheetController else { return }
            
            let effectView = actionController.backgroundView
            let mainView = actionController.view
            
            // Condition commented out because, the effect looks quite bad, even though I think this is how Apple wants us to implement this.
            // Fading in the background view instead, actually looks good in my tests, but the system logs a warning for doing it.
            //                    if let effectView = actionController.backgroundView as? UIVisualEffectView {
            //                        effectView.effect = nil
            //                    } else {
            effectView.alpha = 0.0
            //                    }
            
            containerView.addSubview(effectView)
            effectView.leftAnchor.constraintEqualToAnchor(containerView.leftAnchor).active = true
            effectView.rightAnchor.constraintEqualToAnchor(containerView.rightAnchor).active = true
            effectView.heightAnchor.constraintEqualToAnchor(containerView.heightAnchor).active = true
            effectView.topAnchor.constraintEqualToAnchor(containerView.topAnchor).active = true
            containerView.setNeedsUpdateConstraints()
            containerView.layoutIfNeeded()
            
            if let effectView = effectView as? UIVisualEffectView {
                effectView.contentView.addSubview(mainView)
            } else {
                effectView.addSubview(mainView)
            }
            mainView.centerXAnchor.constraintEqualToAnchor(effectView.centerXAnchor).active = true
            mainView.widthAnchor.constraintEqualToAnchor(effectView.widthAnchor).active = true
            mainView.heightAnchor.constraintEqualToAnchor(effectView.heightAnchor).active = true
            let initialConstraint = mainView.topAnchor.constraintEqualToAnchor(effectView.bottomAnchor)
            initialConstraint.active = true
            effectView.setNeedsUpdateConstraints()
            effectView.layoutIfNeeded()
            effectView.removeConstraint(initialConstraint)
            
            actionController.animationConstraint = mainView.bottomAnchor.constraintEqualToAnchor(effectView.bottomAnchor)
            actionController.animationConstraint!.active = true
            
            containerView.setNeedsUpdateConstraints()
            
            var damping: CGFloat = 1.0
            var duration = shortTransitionDuration
            if !actionController.bouncingEffectsDisabled {
                damping = 0.6
                duration = longTransitionDuration
            }
            
            UIView.animateWithDuration(duration, delay: 0.0, usingSpringWithDamping: damping, initialSpringVelocity: 1.0, options: [.BeginFromCurrentState, .AllowUserInteraction], animations: { () -> Void in
                // Condition commented out because the effect looks quite bad, even though I think this is how Apple wants us to implement this.
                // Fading in the background view instead, actually looks good in my tests, but the system logs a warning for doing it.
                //                    if let effectView = actionController.backgroundView as? UIVisualEffectView {
                //                        effectView.effect = UIBlurEffect(style: actionController.backgroundBlurEffectStyleForCurrentStyle)
                //                    } else {
                effectView.alpha = 1.0
                //                    }
                effectView.layoutIfNeeded()
                }, completion: { (finished) -> Void in
                    transitionContext.completeTransition(true)
            })
            
        } else if self.animationStyle == .Dismissing {
            if let actionController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as? ActionSheetController {
                let mainView = actionController.view
                let effectView = actionController.backgroundView
                
                effectView.removeConstraint(actionController.animationConstraint!)
                
                mainView.topAnchor.constraintEqualToAnchor(effectView.bottomAnchor).active = true
                containerView.setNeedsUpdateConstraints()
                
                UIView.animateWithDuration(shortTransitionDuration, delay: 0, options:[.BeginFromCurrentState], animations:{ () -> Void in
                    // Condition commented out because, the effect looks quite bad, even though I think this is how Apple wants us to implement this.
                    // Fading in the background view instead, actually looks good in my tests, but the system logs a warning for doing it.
                    //                    if let effectView = actionController.backgroundView as? UIVisualEffectView {
                    //                        effectView.effect = nil
                    //                    } else {
                    actionController.backgroundView.alpha = 0.0
                    //                    }
                    containerView.layoutIfNeeded()
                    }, completion: { (finished) -> Void in
                        transitionContext.completeTransition(true)
                })
            }
        }
    }
    
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        if self.animationStyle == .Presenting {
            let toViewController = transitionContext?.viewControllerForKey(UITransitionContextToViewControllerKey)
            if let actionController = toViewController as? ActionSheetController {
                if actionController.bouncingEffectsDisabled {
                    return shortTransitionDuration
                } else {
                    return longTransitionDuration
                }
            }
        } else if self.animationStyle == .Dismissing {
            return shortTransitionDuration
        }
        
        return longTransitionDuration
    }
    
}
