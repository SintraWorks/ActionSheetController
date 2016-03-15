//
//  TableViewDataSource.swift
//  ActionSheetController
//
//  Created by Antonio Nunes on 14/03/16.
//  Copyright © 2016 SintraWorks. All rights reserved.
//

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
