//
//  BluetoothManager.swift
//  BluetoothTest
//
//  Created by Rich Long on 27/10/2016.
//  Copyright © 2016 Rich Long. All rights reserved.
//

import UIKit
import CoreBluetooth

enum HexPacketPrefix:UInt8 {
    case TodaysData = 0x43
}

class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var centralManager: CBCentralManager?
    var discoveredPeripheral: CBPeripheral?
    
    var transferCharacteristic:CBCharacteristic?
    var recieveCharacteristic:CBCharacteristic?
    
    let serviceUUID:CBUUID = CBUUID.init(string: "FFF0")
    let transferUUID:CBUUID = CBUUID.init(string: "FFF6")
    let recieveUUID:CBUUID = CBUUID.init(string: "FFF7")
    
    func startScan() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    //Mark: CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        switch central.state {
        case .poweredOff:
            print("Off")
        case .poweredOn:
            print("On")
            scan()
        case .resetting:
            print("Resetting")
        case .unauthorized:
            print("Unauth")
        case .unknown:
            print("unknown")
        case .unsupported:
            print("Unsupport")
        }
        print(central)
    }
    
    private func scan() {
        centralManager?.scanForPeripherals(withServices: [serviceUUID], options: nil)
        print("Scanning started")
    }
    
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        print("Discovered \(peripheral.name) at \(RSSI)")
        
        // Ok, it's in range - have we already seen it?
        
        if let name:String = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            
            if name.contains("NewgenMedicals") {
                
                discoveredPeripheral = peripheral
                
                // And connect
                print("Connecting to peripheral \(peripheral)")
                centralManager?.connect(peripheral, options: nil)
            }

        }
        else {
            print("Cannot connect to peripheral \(peripheral)")
        }
        
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        print("Peripheral Connected")
        
        // Stop scanning
        centralManager?.stopScan()
        print("Scanning stopped")
        
        // Clear the data that we may already have
        //        data.length = 0
        
        // Make sure we get the discovery callbacks
        peripheral.delegate = self
        
        // Search only for services that match our UUID
        peripheral.discoverServices([serviceUUID])
        
    }
    
    
    
    //Mark: CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        for service in peripheral.services! {
            print(service)
            
            if service.uuid == serviceUUID {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        // Deal with errors (if any)
        guard error == nil else {
            print("Error discovering characteristics: \(error!.localizedDescription)")
            cleanup()
            return
        }
        
        guard let characteristics = service.characteristics else {
            return
        }
        
        
        // Again, we loop through the array, just in case.
        for characteristic in characteristics {
            
            if characteristic.uuid == transferUUID {
                self.transferCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                print("tx set: \(characteristic)")
            }
            
            if characteristic.uuid == recieveUUID  {
                self.recieveCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                print("rx set: \(characteristic)")
            }
        }
        // Once this is complete, we just need to wait for the data to come in.
        
        if self.transferCharacteristic != nil && self.recieveCharacteristic != nil {
            // RX & TX Set - request info
            self.getTodaysData()
        }
        
    }
    
    func getTodaysData() {
        
        let data = Data.init(bytes: Packet.createPacket(firstBytes: [HexPacketPrefix.TodaysData.rawValue]))
        self.discoveredPeripheral?.writeValue(data, for: transferCharacteristic!, type: CBCharacteristicWriteType.withResponse)

    }
    
    func processPacket(packet:[UInt8]) {
        
        let firstByte:UInt8 = packet.first!
        
        print(packet)
        
        switch firstByte {
        case HexPacketPrefix.TodaysData.rawValue:
            //Steps
            print("Step packet")
            break
        default:
            print("packet error")
        }
        
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        guard error == nil else {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }

        let data = characteristic.value!
        let hexArray:[UInt8] = data.withUnsafeBytes {
            [UInt8](UnsafeBufferPointer(start: $0, count: data.count))
        }
        
        if hexArray.count > 0 {
            processPacket(packet: hexArray)
        }
        else {
            print("Invalid data recieved")
            return
        }
    }
    
//        
//        
////        print("return: \(array)")
//        
//        guard let stringFromData = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue) else {
//            print("Invalid data")
//            return
//        }
//        
//        print("Received: \(stringFromData)")
//        
//        print(characteristic.properties, characteristic.uuid,characteristic.service,characteristic.value)
//        
//        if let data:Data = characteristic.value {
//            
//            
//            print("Received: \(data.count, data))")
//            
//            //            let b: UInt8 = data.
//            
//            //            print(Character(UnicodeScalar(b)))
//            
//            //            _ = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
//            
//            
//            
//        }
        
        
        
        //        // Have we got everything we need?
        //        if stringFromData.isEqualToString("EOM") {
        //            // We have, so show the data,
        //            textView.text = String(data: data.copy() as! NSData, encoding: NSUTF8StringEncoding)
        //
        //            // Cancel our subscription to the characteristic
        //            peripheral.setNotifyValue(false, forCharacteristic: characteristic)
        //
        //            // and disconnect from the peripehral
        //            centralManager?.cancelPeripheralConnection(peripheral)
        //        } else {
        //            // Otherwise, just add the data on to what we already have
        //            data.appendData(characteristic.value!)
        //
        //            // Log it
        //            print("Received: \(stringFromData)")
        //        }
        //
        //
//    }
    
//    func getPacket(char:CBCharacteristic) {
//        
//        if let data:Data = char.value {
//            
//            data.count
//            
//        }
//        
//        
    
//    }

    //MARK: Clean up methods
    
    /** Call this when things either go wrong, or you're done with the connection.
     *  This cancels any subscriptions if there are any, or straight disconnects if not.
     *  (didUpdateNotificationStateForCharacteristic will cancel the connection if a subscription is involved)
     */
    private func cleanup() {
        // Don't do anything if we're not connected
        // self.discoveredPeripheral.isConnected is deprecated
        guard discoveredPeripheral?.state == .connected else {
            return
        }
        
        // See if we are subscribed to a characteristic on the peripheral
        guard let services = discoveredPeripheral?.services else {
            cancelPeripheralConnection()
            return
        }
        
        for service in services {
            guard let characteristics = service.characteristics else {
                continue
            }
            
            for characteristic in characteristics {
                if (characteristic.uuid.isEqual(transferCharacteristic) ||
                    characteristic.uuid.isEqual(recieveCharacteristic)) &&
                    characteristic.isNotifying {
                    discoveredPeripheral?.setNotifyValue(false, for: characteristic)
                    // And we're done.
                    return
                }
            }
        }
    }
    
    private func cancelPeripheralConnection() {
        // If we've got this far, we're connected, but we're not subscribed, so we just disconnect
        centralManager?.cancelPeripheralConnection(discoveredPeripheral!)
    }
    
}
