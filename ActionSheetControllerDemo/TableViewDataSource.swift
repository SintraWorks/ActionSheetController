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
    case CustomView, BlackCustomView, DatePickerView, TransparentBackground, NoBackgroundTaps, GroupedActions, GroupedActionsBlack
    
    func description() -> String {
        switch self {
        case .CustomView:
            return "Custom"
        case .BlackCustomView:
            return "Custom, Black"
        case .DatePickerView:
            return "Date Picker"
        case TransparentBackground:
            return "Transparent Background and Image button"
        case NoBackgroundTaps:
            return "No Background Taps"
        case GroupedActions:
            return "Grouped Actions"
        case GroupedActionsBlack:
            return "Grouped Actions Black"
        }
    }
    
    static var count: Int = {
        return GroupedActionsBlack.rawValue + 1 }()
}


class TableViewDataSource: NSObject {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return RowIdentifier.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier("Cell") else { return UITableViewCell(style: .Default, reuseIdentifier: "Cell") }
        guard let item = RowIdentifier(rawValue: indexPath.row) else { fatalError("Illegal row index") }
        
        cell.textLabel?.text = item.description()
        
        return cell
    }
}
