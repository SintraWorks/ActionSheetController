//
//  TableViewDataSource.swift
//  ActionSheetController
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


enum RowIdentifier: Int {
    case customView, blackCustomView, datePickerView, transparentBackground, noBackgroundTaps, groupedActions, groupedActionsBlack, viewController
    
    func description() -> String {
        switch self {
        case .customView:
            return "Custom View"
        case .blackCustomView:
            return "Custom View, Black"
        case .datePickerView:
            return "Date Picker View"
        case .transparentBackground:
            return "Transparent Background and Image Button View"
        case .noBackgroundTaps:
            return "No Background Taps View"
        case .groupedActions:
            return "Grouped Actions View"
        case .groupedActionsBlack:
            return "Grouped Actions View Black"
        case .viewController:
            return "Custom View Controller"
        }
    }
    
    static var count: Int = {
        return viewController.rawValue + 1 }()
}


class TableViewDataSource: NSObject {
    func numberOfSectionsInTableView(_ tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return RowIdentifier.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") else { return UITableViewCell(style: .default, reuseIdentifier: "Cell") }
        guard let item = RowIdentifier(rawValue: (indexPath as NSIndexPath).row) else { fatalError("Illegal row index") }
        
        cell.textLabel?.text = item.description()
        
        return cell
    }
}
