//
//  Packet.swift
//  BluetoothTest
//
//  Created by Rich Long on 27/10/2016.
//  Copyright © 2016 Rich Long. All rights reserved.
//

import Foundation

//Utility class
class Packet {
    
    //Creates CRC
    //Converts Uint8 to int then back again as can be out of range for uint8
    //@param: Array of Uint8 (hex) values
    //@return: uint CRC calculation
    class func getCRC(forPacket data:[UInt8]) -> UInt8 {
        
        var counter = 0
        var total:Int = Int(data.first!)
        //Skips first and last
        while counter < data.count - 2 {
            total = total + Int(data[counter + 1])
            counter += 1
        }
        return (UInt8(total & 0xFF))
    }
    
    //Creates packet
    //@param: firstBytes = first bytes of packet with instruction
    //@return: array of UInt8 Bytes
    class func createPacket(firstBytes:[UInt8]) -> [UInt8] {
        
        var packet:[UInt8] = []
        
        //Create empty packet - 16 bit, last bit is crc added later
        var counter = 0
        while counter < 15 {
            packet.append(0x00)
            counter += 1
        }
        
        //Add existing bytes
        counter = 0
        while counter < firstBytes.count {
            packet[counter] = firstBytes[counter]
            counter += 1
        }
        
        //Add CRC
        packet.append(getCRC(forPacket: packet))
        
        return packet
    }
    
    class func stringToHex(string:String) -> UInt8? {
        
        guard (string.rangeOfCharacter(from: NSCharacterSet.decimalDigits) != nil) else {
            print("Error contains non numeric character.")
            return nil
        }
        
        if let value = UInt8(string, radix: 16) {
            return value
        }
        
        return nil
    }
    class func stringToInt(string:String) -> Int? {
        
        let str = string.replacingOccurrences(of: " ", with: "0")
        
        guard (str.rangeOfCharacter(from: NSCharacterSet.decimalDigits) != nil) else {
            print("Error contains non numeric character.")
            return nil
        }
        
        if let number = Int(str) {
            return number
        }
        
        return nil
        
    }

    class func convertPacketToIntArray(packet:[UInt8]) -> [Int] {

        var array = [Int]()
        for byte in packet {
            array.append(Int(byte))
        }
        
        return array
    }
    
    class func convertPacketToIntArrayFromHex(packet:[UInt8]) -> [Int] {
        
        var array = [Int]()
        for byte in packet {
            let string = String(format:"%2X", byte)
            
            if let int = Packet.stringToInt(string: string) {
                array.append(int)
            }
            else {
                array.append(-1)
            }
        }
        
        return array
    }
    

    
}
