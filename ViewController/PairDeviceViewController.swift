//
//  PairDeviceViewController.swift
//  BluetoothTest
//
//  Created by Rich Long on 09/11/2016.
//  Copyright © 2016 Rich Long. All rights reserved.
//

import UIKit
import CoreBluetooth
import FLEX

protocol PedometerDelegate {
    var pedometerReady:Bool {get set}
    func deviceFound(name:String)
    func deviceReady()
    func userInfoRecieved(userInfo:PedometerUserInfo)
    func monthStepsRecieved(steps:[Int])

}

class PairDeviceViewController: UIViewController, PedometerDelegate {

    internal var pedometerReady: Bool = false

    let bluetoothManager = BluetoothManager()
    
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var deviceName: UILabel!
    @IBOutlet weak var deviceId: UILabel!
    
    @IBOutlet weak var getUserInfoButton: UIButton!
    @IBOutlet weak var userInfoLabel: UILabel!
    @IBOutlet weak var todaysStepsButton: UIButton!
    
    @IBOutlet weak var getMonthStepsButton: UIButton!
    @IBOutlet weak var monthStepsTextView: UITextView!
    @IBOutlet weak var pairingLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bluetoothManager.delegate = self
        
    }
    
    func deviceFound(name:String) {
        statusLabel.text = "Device found: \(name)"
        
        if let deviceIdString = bluetoothManager.discoveredPeripheral?.identifier {
            deviceId.text = "Device ID: \(deviceIdString)"
            deviceId.adjustsFontSizeToFitWidth = true
        }
        pairingLabel.text = "Pairing..."

    }
    
    func userInfoRecieved(userInfo:PedometerUserInfo) {
        userInfoLabel.text = "Age: \(userInfo.age) Height: \(userInfo.height) Weight: \(userInfo.weight) Stride: \(userInfo.stridgeLength)"
    }
    
    internal func monthStepsRecieved(steps: [Int]) {
        
        var str = ""
        var c = 0
        for int in steps {
            str.append("\nDay: \(c) Steps: \(int)")
            c += 1
        }
        
        monthStepsTextView.text = str
        
    }

    internal func deviceReady() {
        pairingLabel.text = "Paired"
    }

    
    @IBAction func searchButtonAction(_ sender: Any) {
        bluetoothManager.startScan()
        statusLabel.text = "Searching..."
    }
    
    @IBAction func getUserInfoAction(_ sender: Any) {
        
        if pedometerReady {
            bluetoothManager.getUserDetails()
        }
        else {
            userInfoLabel.text = "Device not ready"
        }
    }
    
    @IBAction func getTodaysStepsAction(_ sender: Any) {
        if pedometerReady && !bluetoothManager.isRecievingStepData {
            bluetoothManager.getTodaysData()
            monthStepsTextView.text = "Calculating..."
        }
        else {
            monthStepsTextView.text = "Device not ready"
        }

    }

    @IBAction func getMonthStepsAction(_ sender: Any) {
        if pedometerReady &&
            !bluetoothManager.isRecievingStepData {
            bluetoothManager.get30DaysData()
            monthStepsTextView.text = "Calculating, can take a while."

        }
        else {
            monthStepsTextView.text = "Device not ready"
        }

    }
    @IBAction func debugAction(_ sender: Any) {
        FLEXManager.shared().showExplorer()
    }
}
