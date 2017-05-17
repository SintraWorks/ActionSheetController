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

internal let LightColor = UIColor.white
internal let TransparentLightColor = UIColor.white.withAlphaComponent(0.75)
internal let DarkColor = UIColor.black
internal let TransparentDarkColor = UIColor.black.withAlphaComponent(0.75)
internal let UnblurredBackgroundColorForLightStyle = DarkColor.withAlphaComponent(0.2)
internal let UnblurredBackgroundColorForDarkStyle = LightColor.withAlphaComponent(0.2)
internal let ClearColor = UIColor.clear
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
            return (UIDevice.current.userInterfaceIdiom == .pad) ? 8.0 : 4.0
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
    
    lazy internal var backgroundView: UIView = {
        var backgroundView: UIView? = nil
        if self.blurEffectsDisabled {
            backgroundView = UIView(frame: CGRect.zero)
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
    public var contentViewController: UIViewController?
    
    /// Returns a UIView to be used as a separator row between the top and bottom stack views.
    private func interStackViewSeparatorView() -> UIView {
        let emptyView = UIView(frame: CGRect.zero)
        emptyView.backgroundColor = ClearColor
        emptyView.heightAnchor.constraint(equalToConstant: self.interStackViewheightAnchorConstraint).isActive = true
        return emptyView
    }
    
    /// Returns a UILabel with the majority of settings preapared for use in this controller. Only the font needs setting by the caller.
    private func label(text: String) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.textAlignment = .center
        label.textColor = self.style == .Light ? UIColor.darkGray : UIColor.lightGray
        label.backgroundColor = UIColor.clear
        label.numberOfLines = 0
        return label
    }
    
    /// Returns a UIStackView prepared for use in this controller.
    private func stackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        return stackView
    }
    
    /// Returns a view to enclose a stack view (top ro bottom), prepared such that the stack view will display rounded corners.
    private func roundedCornerContainerForView(view: UIView) -> UIView {
        let roundedCornerContainerView = UIView(frame: CGRect.zero)
        roundedCornerContainerView.layer.cornerRadius = 4
        roundedCornerContainerView.layer.masksToBounds = true
        roundedCornerContainerView.backgroundColor = self.contextAwareBackgroundColor
        
        roundedCornerContainerView.addSubview(view)
        view.leftAnchor.constraint(equalTo: roundedCornerContainerView.leftAnchor).isActive = true
        view.topAnchor.constraint(equalTo: roundedCornerContainerView.topAnchor).isActive = true
        view.rightAnchor.constraint(equalTo: roundedCornerContainerView.rightAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: roundedCornerContainerView.bottomAnchor).isActive = true
        
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
            return .dark
        case .Dark:
            return .light;
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
        let separatorViewHeight: CGFloat = 1.0 / UIScreen.main.scale
        let separatorView = UIView(frame: CGRect.zero)
        separatorView.backgroundColor = UIColor.darkGray
        separatorView.heightAnchor.constraint(equalToConstant: separatorViewHeight).isActive = true
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
            self.add(action: cancelAction)
        }
        if let okAction = okAction {
            self.add(action: okAction)
        }
        self.setup()
    }
    
    
    /// Initializer when loaded from nib.
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
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
    
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animationController = ActionControllerAnimationController()
        animationController.animationStyle = .presenting
        return animationController
    }
    
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animationController = ActionControllerAnimationController()
        animationController.animationStyle = .dismissing
        return animationController
    }
    
    private func setup() {
        self.modalPresentationStyle = .overCurrentContext
        self.transitioningDelegate = self // transitioningDelegate is a weak property, so no retain cycle created here.
    }
    
    private func setupViewHierarchy() {
        self.view.backgroundColor = UIColor.clear
        self.view.translatesAutoresizingMaskIntoConstraints = false
        
        let outerStackView = self.outerStackView
        
        self.setupTopStackView()
        let topContainer = self.roundedCornerContainerForView(view: self.topStackView)
        outerStackView.addArrangedSubview(topContainer)
        
        if self.cancelActions.count > 0 {
            outerStackView.addArrangedSubview(self.interStackViewSeparatorView())
            self.setupBottomStackView()
            let bottomContainer = self.roundedCornerContainerForView(view: bottomStackView)
            outerStackView.addArrangedSubview(bottomContainer)
        }
        
        self.view.addSubview(outerStackView)
        outerStackView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        outerStackView.widthAnchor.constraint(equalTo: self.view.widthAnchor, constant: -20.0).isActive = true
        outerStackView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -8.0).isActive = true
    }
    
    private func setupTopStackView() {
        if self.title != nil || self.message != nil {
            let headerView = UIView()
            var titleLabel: UILabel? = nil
            
            if let title = self.title {
                let label = self.label(text: title)
                label.font = UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)
                
                headerView.addSubview(label)
                label.centerXAnchor.constraint(equalTo: headerView.centerXAnchor).isActive = true
                label.widthAnchor.constraint(equalTo: headerView.widthAnchor, constant: -20.0).isActive = true
                label.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 10.0).isActive = true
                
                if self.message == nil {
                    label.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -10.0).isActive = true
                }
                
                titleLabel = label
            }
            
            if let message = self.message {
                let label = self.label(text: message)
                label.font = UIFont.systemFont(ofSize: UIFont.systemFontSize)
                
                headerView.addSubview(label)
                label.centerXAnchor.constraint(equalTo: headerView.centerXAnchor).isActive = true
                label.widthAnchor.constraint(equalTo: headerView.widthAnchor, constant: -20.0).isActive = true
                label.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -10.0).isActive = true
                
                let relatedAnchor = (titleLabel != nil) ? titleLabel!.bottomAnchor : headerView.topAnchor
                label.topAnchor.constraint(equalTo: relatedAnchor, constant: 10.0).isActive = true
            }
            
            self.topStackView.addArrangedSubview(headerView)
            self.topStackView.addArrangedSubview(self.separatorView())
        }
        
        for action in self.additionalActions {
            self.topStackView.addArrangedSubview(action.view)
            self.topStackView.addArrangedSubview(separatorView())
        }
        
        var subview = self.contentView
        if let contentController = contentViewController {
            subview = contentController.view
        }

        if let middleView = subview {
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
    public func add(action: ActionSheetControllerAction) {
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
            self.dismiss(animated: true, completion: nil)
        }
    }
}
