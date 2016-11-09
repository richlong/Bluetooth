//
//  PairDeviceViewController.swift
//  BluetoothTest
//
//  Created by Rich Long on 09/11/2016.
//  Copyright © 2016 Rich Long. All rights reserved.
//

import UIKit
import CoreBluetooth

protocol PedometerDelegate {
    var pedometerReady:Bool {get set}
    func deviceFound(name:String)
    func userInfoRecieved(userInfo:PedometerUserInfo)
    func todayStepsRecieved(steps:Int)
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
    @IBOutlet weak var todaysStepsLabel: UILabel!
    @IBOutlet weak var monthStepsTextView: UITextView!
    
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
    }
    
    func userInfoRecieved(userInfo:PedometerUserInfo) {
        userInfoLabel.text = "Age: \(userInfo.age) Height: \(userInfo.height) Weight: \(userInfo.weight) Stride: \(userInfo.stridgeLength)"
    }
    
    internal func todayStepsRecieved(steps: Int) {
        todaysStepsLabel.text = "Today's Steps \(steps)"
    }
    
    internal func monthStepsRecieved(steps: [Int]) {
        
        var str = ""
        for int in steps {
            str.append("\n\(int)")
        }
        
        monthStepsTextView.text = str
        
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
        if pedometerReady && !bluetoothManager.isRecievingPastData {
            bluetoothManager.getTodaysData()
            todaysStepsLabel.text = "Calculating..."
        }
        else {
            todaysStepsLabel.text = "Device not ready"
        }

    }

    @IBAction func getMonthStepsAction(_ sender: Any) {
        if pedometerReady &&
            !bluetoothManager.isRecievingTodaysSteps &&
            !bluetoothManager.isRecievingPastData{
            bluetoothManager.get30DaysData()
//            bluetoothManager.getDaysData(day: 2)
        }
        else {
            monthStepsTextView.text = "Device not ready"
        }

    }
}
