//
//  ViewController.swift
//  BT
//
//  Created by Rich Long on 26/10/2016.
//  Copyright © 2016 Renishaw. All rights reserved.
//


import UIKit
import CoreBluetooth


class ViewController: UIViewController {
    
    let bt = BluetoothManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bt.startScan()
    }
}
