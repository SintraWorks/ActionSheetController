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

internal let whiteColor = UIColor.whiteColor()
internal let transparentWhiteColor = UIColor.whiteColor().colorWithAlphaComponent(0.75)
internal let blackColor = UIColor.blackColor()
internal let transparentBlackColor = UIColor.blackColor().colorWithAlphaComponent(0.75)
internal let unblurredBackgroundColorForLightStyle = blackColor.colorWithAlphaComponent(0.2)
internal let unblurredBackgroundColorForDarkStyle = whiteColor.colorWithAlphaComponent(0.2)
internal let clearColor = UIColor.clearColor()
internal let stackViewRowHeightAnchorConstraint: CGFloat = 44.0

// MARK: - Controller

/// The controller style determines the overall theme of the controller. Either White or Black.

public enum ActionSheetControllerStyle: Int {
    /// The white theme, with a light background.
    case White
    /// The black theme, with a dark background.
    case Black
}


/// iOS control for presenting a view in a style reminiscent of an action sheet/alert.
/// You can add a custom view, and any number of buttons to represent and handle actions.

public class ActionSheetController: UIViewController, UIViewControllerTransitioningDelegate, UIPopoverPresentationControllerDelegate {
    private let interStackViewheightAnchorConstraint: CGFloat = 16.0
    private var cornerRadius: CGFloat {
        get {
            return (UIDevice.currentDevice().userInterfaceIdiom == .Pad) ? 8.0 : 4.0
        }
    }

    private(set) var style: ActionSheetControllerStyle = .White

    /// The message shown in the header of the controller.
    public var message: String?
    /// Whether to disable background taps. When true, tapping outside the controller has no effect.
    /// When false, tapping outside the controller dismisses the controller without triggering any actions.
    public var disableBackgroundTaps: Bool = false

    private var stackViewContainer: UIView = {
        let stackViewContainer = UIView(frame: CGRectZero)
        stackViewContainer.translatesAutoresizingMaskIntoConstraints = false
        stackViewContainer.backgroundColor = clearColor
        return stackViewContainer
    }()
    
    private var combinedStackView: UIStackView = {
        let stackView = UIStackView(frame: CGRectZero)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .Vertical
        stackView.distribution = .Fill
        return stackView
    }()

    private var topStackView: UIStackView = {
        let stackView = UIStackView(frame: CGRectZero)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .Vertical
        stackView.distribution = .Fill
        return stackView
    }()

    private var bottomStackView: UIStackView = {
        let stackView = UIStackView(frame: CGRectZero)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .Vertical
        stackView.distribution = .Fill
        return stackView
    }()

    /// Set the contentView to hold the view you want to display. If you need only buttons, do not set the content view.
    public var contentView: UIView?

    lazy private var backgroundView: UIView = {
        var backgroundView: UIView? = nil
        if self.blurEffectsDisabled {
            backgroundView = UIView(frame: CGRectZero)
            backgroundView?.backgroundColor = self.style == .White ?  unblurredBackgroundColorForLightStyle : unblurredBackgroundColorForDarkStyle
        } else {
            let effect = UIBlurEffect(style: self.backgroundBlurEffectStyleForCurrentStyle)
            backgroundView = UIVisualEffectView(effect: effect)
        }
        
        guard let resultView = backgroundView else { fatalError("Could not create backgroundView") }
        resultView.translatesAutoresizingMaskIntoConstraints = false
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: Selector("backgroundViewTapped"))
        resultView.addGestureRecognizer(tapRecognizer)
        
        return resultView
    }()
    
    lazy private var headerTitleLabel: UILabel = {
        let label = UILabel(frame: CGRectZero)
        label.backgroundColor = clearColor
        label.textColor = self.style == .White ?  UIColor.darkGrayColor() : UIColor.lightGrayColor()
        label.font = UIFont.boldSystemFontOfSize(UIFont.systemFontSize())
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .Center
        label.numberOfLines = 0
        return label
    }()
    
    lazy private var headerMessageLabel: UILabel = {
        let label = UILabel(frame: CGRectZero)
        label.backgroundColor = clearColor
        label.textColor = self.style == .White ?  UIColor.darkGrayColor() : UIColor.lightGrayColor()
        label.font = UIFont.systemFontOfSize(UIFont.systemFontSize())
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .Center
        label.numberOfLines = 0;
        return label
    }()
    
    var doneActions: [ActionSheetControllerAction] = []
    var cancelActions: [ActionSheetControllerAction] = []
    var additionalActions: [ActionSheetControllerAction] = []
    
    /// Set to true to let the persenting view shine through without blur effect.
    public var disableBlurEffects: Bool = false
    private var backgroundBlurEffectStyleForCurrentStyle: UIBlurEffectStyle {
        switch (self.style) {
        case .White:
            return .Dark
        case .Black:
            return .Light;
        }
    }
    
    private var _disableBouncingEffects: Bool = false
    /// Set to true to disable bouncing when showing the controller.
    public var disableBouncingEffects: Bool {
        get {
            if UIAccessibilityIsReduceMotionEnabled() {
                return true
            }
            
            return _disableBouncingEffects
        }
        set {
            _disableBouncingEffects = newValue
        }
    }
    
    internal var yConstraint: NSLayoutConstraint?
    
    /// Initializer. Style defaults to White. Generally you will want to pass in at least a title and/or a message.
    /// Pass in any of the other arguments as needed. If you want to add more actions than the Cancel and/or OK actions, you can do so after instantiation.
    /// - Parameter style: The controller's style. Either White or Black.
    /// - Parameter title: The title shown in the controller's header.
    /// - Parameter message: The message shown in the controller's header.
    /// - Parameter cancelAction: A action appropriately configured for cancelling abd dismissing the controller.
    /// - Parameter okAction: A action appropriately configured for actioning on and dismissing the controller.
    public init(style: ActionSheetControllerStyle = .White, title: String?, message: String?, cancelAction: ActionSheetControllerAction? = nil, okAction: ActionSheetControllerAction? = nil) {
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
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.setup()
    }
    
    /// Initializer when loaded from a decoder.
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    private func setup() {
        self.modalPresentationStyle = .OverCurrentContext
        self.transitioningDelegate = self
    }
    
    /// Whether blur effects are disabled or not.
    public var blurEffectsDisabled: Bool {
        get {
            if UIAccessibilityIsReduceTransparencyEnabled() {
                return true
            }
            return disableBlurEffects
        }
    }
    
    
    /// Forcibly public. Move on. Nothing to see here.
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.translatesAutoresizingMaskIntoConstraints = true
        self.view.backgroundColor = clearColor
        self.view.layer.masksToBounds = true

        if self.modalPresentationStyle != .Popover {
            self.view.addSubview(self.backgroundView)
            self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-(0)-[BGView]-(0)-|", options: [NSLayoutFormatOptions(rawValue: 0)], metrics: nil, views: ["BGView" : self.backgroundView]))
            self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-(0)-[BGView]-(0)-|", options: [NSLayoutFormatOptions(rawValue: 0)], metrics: nil, views: ["BGView" : self.backgroundView]))
        }

        self.setupStackViews()
        
        let minimalSize = self.view.systemLayoutSizeFittingSize(CGSizeMake(999, 999))
        self.preferredContentSize = CGSizeMake(minimalSize.width, minimalSize.height + 10);
        
        self.popoverPresentationController?.delegate = self

        if UIDevice.currentDevice().userInterfaceIdiom != .Pad {
            self.addMotionEffects()
        }
    }
    
    
    private func addMotionEffects() {
        let verticalMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.y", type: .TiltAlongVerticalAxis)
        verticalMotionEffect.minimumRelativeValue = -10
        verticalMotionEffect.maximumRelativeValue = 10
        
        let horizontalMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.x", type: .TiltAlongHorizontalAxis)
        horizontalMotionEffect.minimumRelativeValue = -10
        horizontalMotionEffect.maximumRelativeValue = 10
        
        let motionEffectGroup = UIMotionEffectGroup()
        motionEffectGroup.motionEffects = [horizontalMotionEffect, verticalMotionEffect]
        
        self.view.addMotionEffect(motionEffectGroup)
    }
    

    private func setupStackViews() {
        setupTopStackView()
        
        if self.cancelActions.count > 0 {
            self.combinedStackView.addArrangedSubview(self.interStackViewSeparatorView())
            setupBottomStackView()
        }

        var viewsDict: [String : UIView] = ["stackView" : self.combinedStackView]
        self.stackViewContainer.addSubview(self.combinedStackView)
        self.stackViewContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-(0)-[stackView]-(0)-|", options: [NSLayoutFormatOptions(rawValue: 0)], metrics: nil, views: viewsDict))
        self.stackViewContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-(0)-[stackView]-(0)-|", options: [NSLayoutFormatOptions(rawValue: 0)], metrics: nil, views: viewsDict))

        var baseView = self.view
        
        if let effectView = self.backgroundView as? UIVisualEffectView where self.modalPresentationStyle != .Popover {
            baseView = effectView.contentView
        }
        
        viewsDict = ["stackViewContainer" : self.stackViewContainer]
        baseView.addSubview(self.stackViewContainer)
        baseView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-(10)-[stackViewContainer]-(10)-|", options: [NSLayoutFormatOptions(rawValue: 0)], metrics: nil, views: viewsDict))
        baseView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-(10)-[stackViewContainer]-(10)-|", options: [NSLayoutFormatOptions(rawValue: 0)], metrics: nil, views: viewsDict))

    }

    
    private func interStackViewSeparatorView() -> UIView {
        let emptyView = UIView(frame: CGRectZero)
        emptyView.backgroundColor = clearColor
        emptyView.heightAnchor.constraintEqualToConstant(interStackViewheightAnchorConstraint).active = true
        return emptyView
    }
    
    
    private func separatorView() -> UIView {
        let separatorViewHeight: CGFloat = 1.0 / UIScreen.mainScreen().scale
        let separatorView = UIView(frame: CGRectZero)
        separatorView.backgroundColor = UIColor.darkGrayColor()
        separatorView.heightAnchor.constraintEqualToConstant(separatorViewHeight).active = true
        return separatorView
    }
    
    
    private func contextAwareWhiteColor() -> UIColor {
        return self.blurEffectsDisabled ? whiteColor : transparentWhiteColor
    }
    

    private func contextAwareBlackColor() -> UIColor {
        return self.blurEffectsDisabled ? blackColor : transparentBlackColor
    }
    
    
    private func contextAwareBackgroundColor() -> UIColor {
        switch self.style {
        case .White:
            return self.contextAwareWhiteColor()
        case .Black:
            return self.contextAwareBlackColor()
        }
    }

    
    private func setupTopStackView() {
        let sideMarginsMetrics = ["sideMargins" : 10.0]
 
        let headerView = UIView(frame: CGRectZero)
        headerView.backgroundColor = self.contextAwareBackgroundColor()
        
        if self.title != nil {
            self.headerTitleLabel.text = self.title
            headerView.addSubview(self.headerTitleLabel)
            headerView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-(sideMargins)-[label]-(sideMargins)-|", options: [NSLayoutFormatOptions(rawValue: 0)], metrics: sideMarginsMetrics, views: ["label" : self.headerTitleLabel]))
            headerView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-(10)-[label]", options: [NSLayoutFormatOptions(rawValue: 0)], metrics: nil, views: ["label" : self.headerTitleLabel]))
            if self.message == nil {
                headerView.addConstraint(NSLayoutConstraint(item: self.headerTitleLabel, attribute: .Bottom, relatedBy: .Equal, toItem: headerView, attribute: .Bottom, multiplier: 1.0, constant: 10.0))
            }
        }

        if self.message != nil {
            self.headerMessageLabel.text = self.message
            headerView.addSubview(self.headerMessageLabel)
            headerView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-(sideMargins)-[label]-(sideMargins)-|", options: [NSLayoutFormatOptions(rawValue: 0)], metrics: sideMarginsMetrics, views: ["label" : self.headerMessageLabel]))
            headerView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[label]-(10)-|", options: [NSLayoutFormatOptions(rawValue: 0)], metrics: nil, views: ["label" : self.headerMessageLabel]))
            if self.title == nil {
                headerView.addConstraint(NSLayoutConstraint(item: self.headerMessageLabel, attribute: .Top, relatedBy: .Equal, toItem: headerView, attribute: .Top, multiplier: 1.0, constant: 10.0))
            } else {
                headerView.addConstraint(NSLayoutConstraint(item: self.headerMessageLabel, attribute: .Top, relatedBy: .Equal, toItem: self.headerTitleLabel, attribute: .Bottom, multiplier: 1.0, constant: 8.0))
            }
        }
        self.topStackView.addArrangedSubview(headerView)
        self.topStackView.addArrangedSubview(separatorView())
        
        for action in self.additionalActions {
            self.topStackView.addArrangedSubview(action.view)
            self.topStackView.addArrangedSubview(separatorView())
        }

        if let middleView = self.contentView {
            middleView.backgroundColor = self.contextAwareBackgroundColor()
            self.topStackView.addArrangedSubview(middleView)
            self.topStackView.addArrangedSubview(separatorView())
        }
    
        for action in self.doneActions {
            self.topStackView.addArrangedSubview(action.view)
            if action !== self.doneActions.last! {
                self.topStackView.addArrangedSubview(separatorView())
            }
        }
        
        self.combinedStackView.addArrangedSubview(self.roundedCornerContainerForView(self.topStackView))
    }
    
    
    private func setupBottomStackView() {
        for action in self.cancelActions {
            self.bottomStackView.addArrangedSubview(action.view)
            if action !== self.cancelActions.last! {
                self.bottomStackView.addArrangedSubview(separatorView())
            }
        }
        
        self.combinedStackView.addArrangedSubview(self.roundedCornerContainerForView(self.bottomStackView))
    }
    
    
    private func blur() -> UIBlurEffect {
        return UIBlurEffect(style: self.containerBlurEffectStyleForCurrentStyle())
    }
    
    
    private func roundedCornerContainerForView(view: UIView) -> UIView {
        let roundedCornerContainerView = UIView(frame: CGRectZero)
        roundedCornerContainerView.layer.cornerRadius = cornerRadius
        roundedCornerContainerView.layer.masksToBounds = true
        roundedCornerContainerView.addSubview(view)
        let viewsDict: [String : UIView] = ["view" : view]
        roundedCornerContainerView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-(0)-[view]-(0)-|", options: [NSLayoutFormatOptions(rawValue: 0)], metrics: nil, views: viewsDict))
        roundedCornerContainerView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-(0)-[view]-(0)-|", options: [NSLayoutFormatOptions(rawValue: 0)], metrics: nil, views: viewsDict))
        return roundedCornerContainerView
    }
    
    
    private func containerBlurEffectStyleForCurrentStyle() -> UIBlurEffectStyle {
        switch (self.style) {
        case .White:
            return .Light;
        case .Black:
            return .Dark;
        }
    }

    /// Forcibly public. Move on. Nothing to see here.
    public func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animationController = ActionControllerAnimationController()
        animationController.animationStyle = .Presenting
        return animationController
    }
    
    
    /// Forcibly public. Move on. Nothing to see here.
    public func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animationController = ActionControllerAnimationController()
        animationController.animationStyle = .Dismissing
        return animationController
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
    
    private let longTransitionDuration: NSTimeInterval = 1.0
    private let shortTransitionDuration: NSTimeInterval = 0.3
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        guard let containerView = transitionContext.containerView() else { return }
        
        if self.animationStyle == .Presenting {
            let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)
            if let actionController = toVC as? ActionSheetController {
                // Condition commented out because, the effect looks quite bad, even though I think this is how Apple wants us to implement this.
                // Fading in the background view instead, actually looks good in my tests, but the system logs a warning for doing it.
//                    if let effectView = actionController.backgroundView as? UIVisualEffectView {
//                        effectView.effect = nil
//                    } else {
                        actionController.backgroundView.alpha = 0.0
//                    }
                containerView.addSubview(actionController.view)
                containerView.addSubview(actionController.backgroundView)
                containerView.addSubview(actionController.stackViewContainer)

                let backgroundViewBindingsDict = ["BGView": actionController.backgroundView]
                let baseViewBindingsDict = ["BaseView": actionController.view]

                containerView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-(0)-[BaseView]-(0)-|", options:[NSLayoutFormatOptions(rawValue: 0)], metrics:nil, views:baseViewBindingsDict))
                containerView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-(0)-[BaseView]-(0)-|", options:[NSLayoutFormatOptions(rawValue: 0)], metrics:nil, views:baseViewBindingsDict))

                containerView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-(0)-[BGView]-(0)-|", options:[NSLayoutFormatOptions(rawValue: 0)], metrics:nil, views:backgroundViewBindingsDict))
                containerView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-(0)-[BGView]-(0)-|", options:[NSLayoutFormatOptions(rawValue: 0)], metrics:nil, views:backgroundViewBindingsDict))

                containerView.addConstraint(NSLayoutConstraint(item: actionController.stackViewContainer, attribute: .CenterX, relatedBy: .Equal, toItem: containerView, attribute: .CenterX, multiplier: 1.0, constant: 0.0))
                containerView.addConstraint(NSLayoutConstraint(item: actionController.stackViewContainer, attribute: .Width, relatedBy: .Equal, toItem: containerView, attribute: .Width, multiplier: 1.0, constant: -20.0))

                actionController.yConstraint = NSLayoutConstraint(item: actionController.stackViewContainer, attribute: .Top, relatedBy: .Equal, toItem:containerView, attribute:.Bottom, multiplier:1, constant:0)
                containerView.addConstraint(actionController.yConstraint!)

                containerView.setNeedsUpdateConstraints()
                containerView.layoutIfNeeded()

                containerView.removeConstraint(actionController.yConstraint!)
                actionController.yConstraint = NSLayoutConstraint(item: actionController.stackViewContainer, attribute: .Bottom, relatedBy: .Equal, toItem:containerView, attribute:.Bottom, multiplier:1, constant:-10)
                containerView.addConstraint(actionController.yConstraint!)

                containerView.setNeedsUpdateConstraints()

                var damping: CGFloat = 1.0
                var duration = shortTransitionDuration
                if !actionController.disableBouncingEffects {
                    damping = 0.6
                    duration = longTransitionDuration
                }

                UIView.animateWithDuration(duration, delay: 0.0, usingSpringWithDamping: damping, initialSpringVelocity: 1.0, options: [.BeginFromCurrentState, .AllowUserInteraction], animations: { () -> Void in
                    // Condition commented out because the effect looks quite bad, even though I think this is how Apple wants us to implement this.
                    // Fading in the background view instead, actually looks good in my tests, but the system logs a warning for doing it.
//                    if let effectView = actionController.backgroundView as? UIVisualEffectView {
//                        effectView.effect = UIBlurEffect(style: actionController.backgroundBlurEffectStyleForCurrentStyle)
//                    } else {
                        actionController.backgroundView.alpha = 1.0
//                    }
                    containerView.layoutIfNeeded()
                    }, completion: { (finished) -> Void in
                        transitionContext.completeTransition(true)
                })
            }
        } else if self.animationStyle == .Dismissing {
            let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)
            if let actionController = fromVC as? ActionSheetController {
                containerView.removeConstraint(actionController.yConstraint!)
                actionController.yConstraint = NSLayoutConstraint(item:actionController.stackViewContainer, attribute:.Top, relatedBy:.Equal, toItem:containerView, attribute:.Bottom, multiplier:1, constant:0)
                containerView.addConstraint(actionController.yConstraint!)

                containerView.setNeedsUpdateConstraints()

                UIView.animateWithDuration(0.25, delay: 0, options:[.BeginFromCurrentState], animations:{ () -> Void in
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
                if actionController.disableBouncingEffects {
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
