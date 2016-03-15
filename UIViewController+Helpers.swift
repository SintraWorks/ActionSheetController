//
//  UIViewController+Helpers.swift
//  RandomReminders
//
//  Created by Antonio Nunes on 17/02/16.
//  Copyright © 2016 SintraWorks. All rights reserved.
//

import UIKit

extension UIViewController {
    func presentViewControllerOnMainThread(viewControllerToPresent: UIViewController,
        animated flag: Bool,
        completion: (() -> Void)?) {
            dispatch_async(dispatch_get_main_queue()) {
                self.presentViewController(viewControllerToPresent, animated: flag, completion: completion)
            }
    }
}
