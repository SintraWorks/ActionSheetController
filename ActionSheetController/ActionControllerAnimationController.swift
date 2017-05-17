//
//  ActionControllerAnimationController.swift
//  ActionSheetController
//
//  Created by Antonio Nunes on 17/05/2017.
//  Copyright © 2017 SintraWorks. All rights reserved.
//

import UIKit

internal enum ActionControllerAnimationStyle {
    case presenting
    case dismissing
}

// MARK: - Animation (only on .Phone idiom devices)
class ActionControllerAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    internal var animationStyle: ActionControllerAnimationStyle = .presenting
    
    private let longTransitionDuration: TimeInterval = 1.5
    private let shortTransitionDuration: TimeInterval = 0.3
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        
        if self.animationStyle == .presenting {
            guard let actionController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) as? ActionSheetController else { return }
            
            let effectView = actionController.backgroundView
            let mainView = actionController.view!
            
            // Condition commented out because the effect looks quite bad, even though I think this is how Apple wants us to implement this.
            // Fading in the background view instead, actually looks good in my tests, but the system logs a warning for doing it.
            //                    if let effectView = actionController.backgroundView as? UIVisualEffectView {
            //                        effectView.effect = nil
            //                    } else {
            effectView.alpha = 0.0
            //                    }
            
            containerView.addSubview(effectView)
            effectView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
            effectView.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
            effectView.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
            effectView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
            containerView.setNeedsUpdateConstraints()
            containerView.layoutIfNeeded()
            
            if let effectView = effectView as? UIVisualEffectView {
                effectView.contentView.addSubview(mainView)
            } else {
                effectView.addSubview(mainView)
            }
            
            mainView.centerXAnchor.constraint(equalTo: effectView.centerXAnchor).isActive = true
            mainView.widthAnchor.constraint(equalTo: effectView.widthAnchor).isActive = true
            mainView.heightAnchor.constraint(equalTo: effectView.heightAnchor).isActive = true
            let initialConstraint = mainView.topAnchor.constraint(equalTo: effectView.bottomAnchor)
            initialConstraint.isActive = true
            effectView.setNeedsUpdateConstraints()
            effectView.layoutIfNeeded()
            effectView.removeConstraint(initialConstraint)
            
            actionController.animationConstraint = mainView.bottomAnchor.constraint(equalTo: effectView.bottomAnchor)
            actionController.animationConstraint!.isActive = true
            
            containerView.setNeedsUpdateConstraints()
            
            var damping: CGFloat = 1.0
            var duration = shortTransitionDuration
            if !actionController.bouncingEffectsDisabled {
                damping = 0.6
                duration = longTransitionDuration
            }
            
            UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: damping, initialSpringVelocity: 1.0, options: [.beginFromCurrentState, .allowUserInteraction], animations: { () -> Void in
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
        } else if self.animationStyle == .dismissing {
            if let actionController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) as? ActionSheetController {
                let mainView = actionController.view
                let effectView = actionController.backgroundView
                
                effectView.removeConstraint(actionController.animationConstraint!)
                
                mainView?.topAnchor.constraint(equalTo: effectView.bottomAnchor).isActive = true
                containerView.setNeedsUpdateConstraints()
                
                UIView.animate(withDuration: shortTransitionDuration, delay: 0, options:[.beginFromCurrentState], animations:{ () -> Void in
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
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        if self.animationStyle == .presenting {
            let toViewController = transitionContext?.viewController(forKey: UITransitionContextViewControllerKey.to)
            if let actionController = toViewController as? ActionSheetController {
                if actionController.bouncingEffectsDisabled {
                    return shortTransitionDuration
                } else {
                    return longTransitionDuration
                }
            }
        } else if self.animationStyle == .dismissing {
            return shortTransitionDuration
        }
        
        return longTransitionDuration
    }
}
