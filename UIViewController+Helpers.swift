//
//  UIViewController+Helpers.swift
//  RandomReminders
//
//  Created by Antonio Nunes on 17/02/16.
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

extension UIViewController {
    func presentViewControllerOnMainThread(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
        let op = BlockOperation(block: { self.present(viewControllerToPresent, animated: flag, completion: completion) })
        OperationQueue.main.addOperation(op)
    }
    
    class func topViewControllerForViewController(_ queryBaseController: UIViewController) -> UIViewController {
        var targetController = queryBaseController
        var currentController: UIViewController? = targetController
        
        repeat {
            switch currentController {
            case let navigationController as UINavigationController:
                currentController = navigationController.viewControllers.last
            case let tabBarController as UITabBarController:
                currentController = tabBarController.selectedViewController
            default:
                currentController = targetController.presentedViewController
            }
            
            if let currentController = currentController {
                targetController = currentController
            }
        } while currentController != nil
        
        return targetController
    }    
}
