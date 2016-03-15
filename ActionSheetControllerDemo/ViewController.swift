//
//  ViewController.swift
//  ActionSheetControllerDemo
//
//  Created by Antonio Nunes on 14/03/16.
//  Copyright © 2016 SintraWorks. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        var frame = self.tableView.bounds
        frame.size.height = 20.0
        let headerView = UIView(frame: frame)
        headerView.translatesAutoresizingMaskIntoConstraints = false

        self.tableView.tableHeaderView = headerView
    }
}

