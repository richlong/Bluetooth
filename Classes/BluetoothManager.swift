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
    case DaysData = 0x43
    case GetUserDetails = 0x42
    case SetUserDetails = 0x02
    case RealTimeStepMeter = 0x09
    case SetTime = 0x01
    case GetTime = 0x41
    case FactoryReset = 0x12
    case GetCurrentActivityData = 0x48
}

class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var centralManager: CBCentralManager?
    var discoveredPeripheral: CBPeripheral?
    
    var transferCharacteristic:CBCharacteristic?
    var recieveCharacteristic:CBCharacteristic?
    
    let serviceUUID:CBUUID = CBUUID.init(string: "FFF0")
    let transferUUID:CBUUID = CBUUID.init(string: "FFF6")
    let recieveUUID:CBUUID = CBUUID.init(string: "FFF7")
    
    var todayStepCount:Int = 0
    var stepPacketCount:Int = 0
    var monthSteps:[Int] = []
    var isRecievingPastData = false
    func startScan() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    //MARK: CBCentralManagerDelegate
    
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
    
    
    
    //MARK: CBPeripheralDelegate
    
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
//            getTodaysData()
//            setDeviceTime()
//            getDeviceTime()
//            
//            setUserDetails(gender: 00, age: 56, height: 180, weight: 99, strideLength: 99)
//            getUserDetails()
//                getTodaysData()
//            startRealtimeTracking()
//            factoryResetDevice()
            
//            getDaysData(day: 1)
//             getCurrentActivityData()
            get30DaysData()
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
    
    //MARK:
    //MARK: Communication Methods
    
    func sendPacketToDevice(firstBytes:[UInt8]) {
        
        let data = Data.init(bytes: Packet.createPacket(firstBytes: firstBytes))
        self.discoveredPeripheral?.writeValue(data, for: transferCharacteristic!, type: CBCharacteristicWriteType.withResponse)
    }
    
    func processPacket(packet:[UInt8]) {
        
        let firstByte:UInt8 = packet.first!
        
        switch firstByte {
        case HexPacketPrefix.DaysData.rawValue:
            parseDaysData(packet: packet)
            break
        case HexPacketPrefix.GetTime.rawValue:
            parseDate(packet: packet)
            break
        case HexPacketPrefix.RealTimeStepMeter.rawValue:
            print("Realtime step: \(packet)")
            break
        case HexPacketPrefix.GetUserDetails.rawValue:
            parseUserDetails(packet: packet)
            break
        case HexPacketPrefix.SetUserDetails.rawValue:
            print("SetUserDetails: \(packet)")
            break
            
        default:
            print("Packet unknown: \(packet)")
        }
        
    }
    
    //MARK: Realtime
    
    func startRealtimeTracking() {
        sendPacketToDevice(firstBytes:  [HexPacketPrefix.RealTimeStepMeter.rawValue])
    }

    //MARK: Todays data
    
    func get30DaysData() {
        print("Get 30 days data")
        isRecievingPastData = true
        create30DayArray()
        var c = 1
        while c <= 30 {
            print(c)
            //Add space in array for return
            sendPacketToDevice(firstBytes:  [HexPacketPrefix.DaysData.rawValue, UInt8(c)])
            c += 1
        }
        
        print(monthSteps.count)
    }
    
    func create30DayArray() {
        var c = 0
        while c <= 30 {
            //Add space in array for return
            monthSteps.append(0)
            c += 1
        }

    }
    
    func getDaysData(day:Int) {
        //Day 0 = today, 1 = yesterday etc up to 30.
        sendPacketToDevice(firstBytes:  [HexPacketPrefix.DaysData.rawValue, UInt8(day)])
    }
    
    func parseDaysData(packet:[UInt8]) {
        
//        print("Step count \(stepCount) packet count \(stepPacketCount)")
        
//        print(packet)
        // 0x00 = Activity data which is what we want
        if (packet[6] == 0x00) {
            
            let date = NSDate()
            let calendar = NSCalendar.current
            let today = calendar.component(.day, from: date as Date)

            
            let steps = Int(packet[9])+Int(packet[10])*256
            if (isRecievingPastData) {
                
                if let day = Int(String(format:"%2X", packet[4])) {
                    
                    print("day: \(day) steps: \(steps)")
                    
                    monthSteps[day] = steps
                    
                    if day == 1 {
                        isRecievingPastData = false
                        print(monthSteps)
                    }
                }
                
                
            }
            else {
                //Is today's data
                print(packet)
            }
            
            print("---")
//            let calorie = Int(packet[7])+Int(packet[8])*256
//            print("calorie: \(calorie)")

//            let day = String(format:"%2X", packet[4])
            
//            print("day: \(day)")
        

//            print("steps: \(steps)")
///            let distance = Int(packet[11])+Int(packet[12])*256
//            print("distance: \(distance)")
//            
//            let runningSteps = Int(packet[13])+Int(packet[14])*256
//            print("runningSteps: \(runningSteps)")
//
//            print("time \(Int(packet[5]))")
        }
        // 0xff = Sleep data
        else if (packet[6] == 0xff) {
            //Not req
        }
        

        
//        var array = [Int]()
//        if (packet[1] == 0xf0) {
//            if (packet[6] == 0x00) {
////                 showstring = [NSString stringWithFormat:@"运动:%x-%x-%x %d:%d-%d:%d(%d) %.2f卡 %d步 %.2f千米 %d秒  %@",packet[2],packet[3],packet[4],packet[5]*15/60,packet[5]*15%60,(packet[5] + 1)*15/60,(packet[5] + 1)*15%60,packet[5],(packet[7]+packet[8]*256)/100.0,packet[9]+packet[10]*256,(packet[11]+packet[12]*256)/100.0,packet[13]+packet[14]*256,(packet[9]+packet[10]*256)==0?@"":@"⭐️⭐️⭐️"];
////            
//            array.append(Int(packet[2]))
//            array.append(Int(packet[3]))
//                array.append(Int(packet[4]))
//                array.append(Int(packet[5]*15/60))
//                array.append(Int(packet[2]))
//                array.append(Int(packet[2]))
//                array.append(Int(packet[2]))
//                array.append(Int(packet[2]))
//                array.append(Int(packet[2]))
//                array.append(Int(packet[2]))
//
//            
//            
//            }
////            else if (packet[6] == 0xff) {
////                showstring = [NSString stringWithFormat:@"睡眠:%x-%x-%x %d:%d(%d) %d %d %d %d %d %d %d %d",packet[2],packet[3],packet[4],packet[5]*15/60,packet[5]*15%60,packet[5],packet[7],packet[8],packet[9],packet[10],packet[11],packet[12],packet[13],packet[14]];
////            }
//        }
//        else if (packet[1] == 0xff) {
//            showstring = @"当天没有数据";
//        }

//        let packetArray = Packet.convertPacketToIntArrayFromHex(packet: packet)
//        print("parseTodaysData\(packetArray)")

    }

    //MARK: Device time
    
    /*
     0x01 AA BB CC DD EE FF 00 00 00 00 00 00 00 00 CRC
     AA year;BB month;CC day;DD hour;EE minute;FF second。format is BCD，for
     example,12 year，AA = 0x12
     
     Check right and execute OK, then return:: 0x01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 CRC Check error and execute Fail, then return: 0x81 00 00 00 00 00 00 00 00 00 00 00 00 00 00 CRC
     */
    
    func setDeviceTime() {
    
        let date = Date()
        print("Setting device date to: \(date)")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyMMddHHmmss"
        let dateString = dateFormatter.string(from: date)
        let characters = Array(dateString.characters)
        
        var packetArray:[UInt8] = []
        packetArray.append(HexPacketPrefix.SetTime.rawValue)
        
        let year = "\(characters[0])\(characters[1])"
        packetArray.append(Packet.stringToHex(string: year)!)
        
        let month = "\(characters[2])\(characters[3])"
        packetArray.append(Packet.stringToHex(string: month)!)
        
        let day = "\(characters[4])\(characters[5])"
        packetArray.append(Packet.stringToHex(string: day)!)
        
        let hour = "\(characters[6])\(characters[7])"
        packetArray.append(Packet.stringToHex(string: hour)!)
        
        let minute = "\(characters[8])\(characters[9])"
        packetArray.append(Packet.stringToHex(string: minute)!)
        
        let second = "\(characters[10])\(characters[11])"
        packetArray.append(Packet.stringToHex(string: second)!)
        
        sendPacketToDevice(firstBytes:packetArray)
    }
    
    func getDeviceTime() {
        sendPacketToDevice(firstBytes:  [HexPacketPrefix.GetTime.rawValue])
    }
    
    func parseDate(packet:[UInt8]) {
        let packetArray = Packet.convertPacketToIntArrayFromHex(packet: packet)
        print("parseDate: \(packetArray)")
    }
    
    //MARK: User details
    
    /*
     0x02 AA BB CC DD EE FF 00 00 00 00 00 00 00 00CRC
     AA:gender(0 stands for female，1 stands for male)，BB:age，CC:height，DD:weight， EE:stride length;
     
     Check right and execute OK, then return: 0x02 00 00 00 00 00 00 00 00 00 00 00 00 00 00 CRC
     Check error and execute Fail, then return:0x82 00 00 00 00 00 00 00 00 00 00 00 00 00 00 CRC
     
     */
    func setUserDetails(gender:Int,age:Int,height:Int,weight:Int,strideLength:Int) {
        
        var packetArray:[UInt8] = []
        packetArray.append(HexPacketPrefix.SetUserDetails.rawValue)
        packetArray.append(UInt8(gender))
        packetArray.append(UInt8(age))
        packetArray.append(UInt8(height))
        packetArray.append(UInt8(weight))
        packetArray.append(UInt8(strideLength))
        
        print("Setting User details: \(packetArray)")
        sendPacketToDevice(firstBytes:packetArray)
    }


    func getUserDetails() {
        sendPacketToDevice(firstBytes:  [HexPacketPrefix.GetUserDetails.rawValue])
    }
    
    func parseUserDetails(packet:[UInt8]) {
        let packetArray = Packet.convertPacketToIntArray(packet: packet)
        print("parseUserDetails\(packetArray)")
    }
    
    //MARK: Current activitiy data
    
    func getCurrentActivityData() {
        sendPacketToDevice(firstBytes:  [HexPacketPrefix.GetCurrentActivityData.rawValue])
    }

    
    //MARK:Factory Reset
    
    func factoryResetDevice() {
        print("Factory reset device...")
        sendPacketToDevice(firstBytes:  [HexPacketPrefix.FactoryReset.rawValue])
    }
    
}
